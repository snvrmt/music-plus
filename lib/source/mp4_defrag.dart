// Converts a fragmented MP4 (what YouTube serves for audio: moov + many
// moof/mdat pairs of ~10 s each) into a regular MP4 with one sample table
// and one mdat, which the iPhone's player plays from start to end.
// Pure Dart, no Flutter imports, so it can be tested on CI.

import 'dart:typed_data';

class _Box {
  _Box(this.type, this.start, this.headerSize, this.size);
  final String type;
  final int start; // offset of the box header
  final int headerSize;
  final int size; // total size including header
  int get bodyStart => start + headerSize;
  int get end => start + size;
}

List<_Box> _boxes(Uint8List d, int from, int to) {
  final bd = ByteData.sublistView(d);
  final out = <_Box>[];
  var p = from;
  while (p + 8 <= to) {
    var size = bd.getUint32(p);
    final type = String.fromCharCodes(d.sublist(p + 4, p + 8));
    var header = 8;
    if (size == 1) {
      size = bd.getUint64(p + 8);
      header = 16;
    } else if (size == 0) {
      size = to - p;
    }
    if (size < header || p + size > to) break;
    out.add(_Box(type, p, header, size));
    p += size;
  }
  return out;
}

_Box? _child(Uint8List d, _Box parent, String type, {int skip = 0}) {
  for (final b in _boxes(d, parent.bodyStart + skip, parent.end)) {
    if (b.type == type) return b;
  }
  return null;
}

class _Sample {
  _Sample(this.offset, this.size, this.duration);
  final int offset, size, duration;
}

class _Builder {
  final _b = BytesBuilder(copy: false);
  void u8(int v) => _b.addByte(v & 0xff);
  void u32(int v) {
    final x = ByteData(4)..setUint32(0, v);
    _b.add(x.buffer.asUint8List());
  }

  void bytes(List<int> v) => _b.add(v);
  Uint8List take() => _b.takeBytes();
  int get length => _b.length;
}

Uint8List _box(String type, List<int> body) {
  final b = _Builder()
    ..u32(body.length + 8)
    ..bytes(type.codeUnits)
    ..bytes(body);
  return b.take();
}

Uint8List _fullBox(String type, int version, int flags, List<int> body) {
  final h = _Builder()
    ..u8(version)
    ..u8(flags >> 16)
    ..u8(flags >> 8)
    ..u8(flags)
    ..bytes(body);
  return _box(type, h.take());
}

/// Returns a regular MP4, or null when [data] is not fragmented
/// (then it can be played as it is).
Uint8List? defragmentMp4(Uint8List data) {
  final bd = ByteData.sublistView(data);
  final top = _boxes(data, 0, data.length);
  final moov = top.where((b) => b.type == 'moov').firstOrNull;
  if (moov == null || !top.any((b) => b.type == 'moof')) return null;

  final trak = _child(data, moov, 'trak');
  if (trak == null) throw const FormatException('No track in MP4');
  final mdia = _child(data, trak, 'mdia')!;
  final mdhd = _child(data, mdia, 'mdhd')!;
  final minf = _child(data, mdia, 'minf')!;
  final stbl = _child(data, minf, 'stbl')!;
  final stsd = _child(data, stbl, 'stsd')!;

  // Defaults from mvex/trex.
  var defDuration = 0, defSize = 0;
  final mvex = _child(data, moov, 'mvex');
  final trex = mvex == null ? null : _child(data, mvex, 'trex');
  if (trex != null) {
    final p = trex.bodyStart + 4; // version/flags
    defDuration = bd.getUint32(p + 8);
    defSize = bd.getUint32(p + 12);
  }

  // Collect every sample from every fragment.
  final samples = <_Sample>[];
  final chunkSampleCounts = <int>[];
  for (final moof in top.where((b) => b.type == 'moof')) {
    for (final traf in _boxes(data, moof.bodyStart, moof.end).where((b) => b.type == 'traf')) {
      final tfhd = _child(data, traf, 'tfhd');
      if (tfhd == null) continue;
      final tfFlags = bd.getUint32(tfhd.bodyStart) & 0xffffff;
      var p = tfhd.bodyStart + 8; // version/flags + track_ID
      var base = moof.start;
      if (tfFlags & 0x01 != 0) {
        base = bd.getUint64(p);
        p += 8;
      }
      if (tfFlags & 0x02 != 0) p += 4;
      var tDuration = defDuration, tSize = defSize;
      if (tfFlags & 0x08 != 0) {
        tDuration = bd.getUint32(p);
        p += 4;
      }
      if (tfFlags & 0x10 != 0) {
        tSize = bd.getUint32(p);
        p += 4;
      }

      var dataPos = base;
      for (final trun in _boxes(data, traf.bodyStart, traf.end).where((b) => b.type == 'trun')) {
        final flags = bd.getUint32(trun.bodyStart) & 0xffffff;
        var q = trun.bodyStart + 4;
        final count = bd.getUint32(q);
        q += 4;
        if (flags & 0x001 != 0) {
          dataPos = base + bd.getInt32(q);
          q += 4;
        }
        if (flags & 0x004 != 0) q += 4;
        for (var i = 0; i < count; i++) {
          var dur = tDuration, size = tSize;
          if (flags & 0x100 != 0) {
            dur = bd.getUint32(q);
            q += 4;
          }
          if (flags & 0x200 != 0) {
            size = bd.getUint32(q);
            q += 4;
          }
          if (flags & 0x400 != 0) q += 4;
          if (flags & 0x800 != 0) q += 4;
          samples.add(_Sample(dataPos, size, dur));
          dataPos += size;
        }
        if (count > 0) chunkSampleCounts.add(count);
      }
    }
  }
  if (samples.isEmpty) throw const FormatException('No samples in MP4');
  if (samples.last.offset + samples.last.size > data.length) {
    throw const FormatException('MP4 is incomplete');
  }

  final mediaDuration = samples.fold<int>(0, (s, x) => s + x.duration);

  // ---- sample tables ----
  final stts = _Builder();
  final runs = <List<int>>[]; // [count, delta]
  for (final s in samples) {
    if (runs.isNotEmpty && runs.last[1] == s.duration) {
      runs.last[0]++;
    } else {
      runs.add([1, s.duration]);
    }
  }
  stts.u32(runs.length);
  for (final r in runs) {
    stts
      ..u32(r[0])
      ..u32(r[1]);
  }

  final stsz = _Builder()
    ..u32(0)
    ..u32(samples.length);
  for (final s in samples) {
    stsz.u32(s.size);
  }

  final stsc = _Builder();
  final stscEntries = <List<int>>[]; // [firstChunk, samplesPerChunk]
  for (var i = 0; i < chunkSampleCounts.length; i++) {
    if (stscEntries.isEmpty || stscEntries.last[1] != chunkSampleCounts[i]) {
      stscEntries.add([i + 1, chunkSampleCounts[i]]);
    }
  }
  stsc.u32(stscEntries.length);
  for (final e in stscEntries) {
    stsc
      ..u32(e[0])
      ..u32(e[1])
      ..u32(1);
  }

  Uint8List stco(List<int> offsets) {
    final b = _Builder()..u32(offsets.length);
    for (final o in offsets) {
      b.u32(o);
    }
    return _fullBox('stco', 0, 0, b.take());
  }

  // ---- rebuild moov ----
  Uint8List copy(_Box b) => Uint8List.sublistView(data, b.start, b.end);

  Uint8List withDuration(_Box b, int duration, {required bool tkhd}) {
    final out = Uint8List.fromList(copy(b));
    final o = ByteData.sublistView(out);
    final h = b.headerSize;
    final v1 = out[h] == 1;
    // mvhd/mdhd: [vf][ctime][mtime][timescale][duration]
    // tkhd:      [vf][ctime][mtime][track_ID][reserved][duration]
    final pos = h + 4 + (v1 ? 16 : 8) + (tkhd ? 8 : 4);
    if (v1) {
      o.setUint64(pos, duration);
    } else {
      o.setUint32(pos, duration);
    }
    return out;
  }

  final mdhdV1 = data[mdhd.bodyStart] == 1;
  final mediaTimescale = bd.getUint32(mdhd.bodyStart + 4 + (mdhdV1 ? 16 : 8));
  final mvhd = _child(data, moov, 'mvhd')!;
  final mvhdV1 = data[mvhd.bodyStart] == 1;
  final movieTimescale = bd.getUint32(mvhd.bodyStart + 4 + (mvhdV1 ? 16 : 8));
  final movieDuration = mediaTimescale == 0
      ? mediaDuration
      : (mediaDuration * movieTimescale / mediaTimescale).round();

  Uint8List buildMoov(List<int> chunkOffsets) {
    final newStbl = _box('stbl', [
      ...copy(stsd),
      ..._fullBox('stts', 0, 0, stts.take().toList()),
      ..._fullBox('stsc', 0, 0, stsc.take().toList()),
      ..._fullBox('stsz', 0, 0, stsz.take().toList()),
      ...stco(chunkOffsets),
    ]);
    // Builders were consumed; refill them for a possible second pass.
    _refill(stts, runs, stsz, samples, stsc, stscEntries);

    final minfParts = <int>[];
    for (final b in _boxes(data, minf.bodyStart, minf.end)) {
      minfParts.addAll(b.type == 'stbl' ? newStbl : copy(b));
    }
    final mdiaParts = <int>[];
    for (final b in _boxes(data, mdia.bodyStart, mdia.end)) {
      if (b.type == 'minf') {
        mdiaParts.addAll(_box('minf', minfParts));
      } else if (b.type == 'mdhd') {
        mdiaParts.addAll(withDuration(b, mediaDuration, tkhd: false));
      } else {
        mdiaParts.addAll(copy(b));
      }
    }
    final trakParts = <int>[];
    for (final b in _boxes(data, trak.bodyStart, trak.end)) {
      if (b.type == 'mdia') {
        trakParts.addAll(_box('mdia', mdiaParts));
      } else if (b.type == 'tkhd') {
        trakParts.addAll(withDuration(b, movieDuration, tkhd: true));
      } else if (b.type == 'edts') {
        // Edit lists in fragmented files assume fragments; drop them.
      } else {
        trakParts.addAll(copy(b));
      }
    }
    final moovParts = <int>[];
    for (final b in _boxes(data, moov.bodyStart, moov.end)) {
      if (b.type == 'trak') {
        if (b.start == trak.start) moovParts.addAll(_box('trak', trakParts));
      } else if (b.type == 'mvhd') {
        moovParts.addAll(withDuration(b, movieDuration, tkhd: false));
      } else if (b.type == 'mvex') {
        // Fragment defaults are not needed any more.
      } else {
        moovParts.addAll(copy(b));
      }
    }
    return _box('moov', moovParts);
  }

  // Always a plain M4A file type (YouTube's says 'dash').
  final ftypBytes = _box('ftyp',
      [...'M4A '.codeUnits, 0, 0, 2, 0, ...'M4A '.codeUnits, ...'mp42'.codeUnits, ...'isom'.codeUnits]);

  // Chunk offsets depend on moov's size; moov's size doesn't depend on the
  // offset values (fixed 4 bytes each), so build once to measure.
  final probeMoov = buildMoov(List.filled(chunkSampleCounts.length, 0));
  final mdatPayloadStart = ftypBytes.length + probeMoov.length + 8;
  final offsets = <int>[];
  var pos = mdatPayloadStart, si = 0;
  for (final count in chunkSampleCounts) {
    offsets.add(pos);
    for (var i = 0; i < count; i++) {
      pos += samples[si++].size;
    }
  }
  final moovBytes = buildMoov(offsets);

  final mdatSize = samples.fold<int>(0, (s, x) => s + x.size);
  final out = _Builder()
    ..bytes(ftypBytes)
    ..bytes(moovBytes)
    ..u32(mdatSize + 8)
    ..bytes('mdat'.codeUnits);
  for (final s in samples) {
    out.bytes(Uint8List.sublistView(data, s.offset, s.offset + s.size));
  }
  return out.take();
}

void _refill(_Builder stts, List<List<int>> runs, _Builder stsz, List<_Sample> samples,
    _Builder stsc, List<List<int>> stscEntries) {
  stts.u32(runs.length);
  for (final r in runs) {
    stts
      ..u32(r[0])
      ..u32(r[1]);
  }
  stsz
    ..u32(0)
    ..u32(samples.length);
  for (final s in samples) {
    stsz.u32(s.size);
  }
  stsc.u32(stscEntries.length);
  for (final e in stscEntries) {
    stsc
      ..u32(e[0])
      ..u32(e[1])
      ..u32(1);
  }
}
