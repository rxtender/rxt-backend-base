import {
  frame, unframe
} from './dummy_type_rxt.js';

var assert = require('assert');

describe('framing of', function() {
  describe('a string', function() {
    it('should append a newline', function() {
      let packet = frame('abcdef');
      assert.equal(packet, 'abcdef\n');
    });
  });
});

describe('framing of', function() {
  describe('a string containing a new line', function() {
    it('should raise an exception', function() {
      assert.throws(() => {
        frame('abc\ndef');
      });
    });
  });
});

describe('unframing of', function() {
  describe('a complete chunk', function() {
    it('should return a packet', function() {
      const result = unframe('', 'abc\n');
      assert.equal(1, result.packets.length);
      assert.equal('abc', result.packets[0]);
    });
  });
});

describe('unframing of', function() {
  describe('a complete chunk with a context', function() {
    it('should return a packet with context at the begining', function() {
      const result = unframe('123', 'abc\n');
      assert.equal(1, result.packets.length);
      assert.equal('123abc', result.packets[0]);
    });
  });
});

describe('unframing of', function() {
  describe('a partial chunk', function() {
    it('should return a packet and a context', function() {
      const result = unframe('', 'abc\nefg');
      assert.equal(1, result.packets.length);
      assert.equal('abc', result.packets[0]);
      assert.equal('efg', result.context);
    });
  });
});

describe('unframing of', function() {
  describe('a partial chunk with context', function() {
    it('should return a packet and a context', function() {
      const result = unframe('iop', 'abc\nefg');
      assert.equal(1, result.packets.length);
      assert.equal('iopabc', result.packets[0]);
      assert.equal('efg', result.context);
    });
  });
});

describe('unframing of', function() {
  describe('a chunk containing multiple packets', function() {
    it('should return the contained packets', function() {
      const result = unframe('iop', 'abc\nefg\nhij\nklm');
      assert.equal(3, result.packets.length);
      assert.equal('iopabc', result.packets[0]);
      assert.equal('efg', result.packets[1]);
      assert.equal('hij', result.packets[2]);
      assert.equal('klm', result.context);
    });
  });
});
