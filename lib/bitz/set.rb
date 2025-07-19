# frozen_string_literal: true

module Bitz
  # A dynamic bitset implementation with efficient bit manipulation operations.
  # Supports automatic buffer resizing and both mutating and non-mutating operations.
  class Set
    # Creates a new bitset with the specified capacity.
    #
    # @param bits [Integer] the initial capacity in bits (default: 64)
    # @param fill [Boolean] whether to initialize with all bits set (default: false)
    def initialize bits = 64, fill: false
      # round up to the nearest 8 then get byte count
      bytes = ((bits + 7) & -8) / 8
      @fill = fill
      @buffer = "".b
      resize bytes, @fill
    end

    # Sets the bit at the specified position to 1.
    # Automatically resizes the buffer if necessary.
    #
    # @param bit [Integer] the bit position to set (0-indexed)
    # @return [void]
    def set bit
      byte = bit / 8
      while true
        if val = @buffer.getbyte(byte)
          @buffer.setbyte(byte, val | (1 << (bit % 8)))
          break
        else
          resize(@buffer.bytesize * 2, @fill)
        end
      end
    end

    # Sets the bit at the specified position to 0.
    # Automatically resizes the buffer if necessary.
    #
    # @param bit [Integer] the bit position to unset (0-indexed)
    # @return [void]
    def unset bit
      byte = bit / 8
      while true
        if val = @buffer.getbyte(byte)
          @buffer.setbyte(byte, val & ~(1 << (bit % 8)))
          break
        else
          resize(@buffer.bytesize * 2, @fill)
        end
      end
    end

    # Checks if the bit at the specified position is set.
    #
    # @param bit [Integer] the bit position to check (0-indexed)
    # @return [Boolean, nil] true if bit is set, false if unset, nil if position doesn't exist
    def set? bit
      if val = @buffer.getbyte(bit / 8)
        0 != val & (1 << (bit % 8))
      else
        nil
      end
    end

    # Creates a deep copy of the bitset.
    #
    # @param _ [Object] unused parameter (required by Ruby's dup mechanism)
    # @return [void]
    def initialize_copy _
      super
      @buffer = @buffer.dup
    end

    # Returns the number of bits set to 1 in this bitset.
    # Uses efficient popcount algorithm for fast bit counting.
    #
    # @return [Integer] the number of set bits
    def count
      @buffer.each_byte.sum { |byte| popcount(byte) }
    end

    # Returns the current capacity of the bitset in bits.
    #
    # @return [Integer] the total number of bits this bitset can hold
    def capacity
      @buffer.bytesize * 8
    end

    # Sets all bits in the bitset to 1.
    #
    # @return [void]
    def set_all
      @buffer.bytesize.times { |index| @buffer.setbyte(index, 0xFF) }
    end

    # Sets all bits in the bitset to 0.
    #
    # @return [void]
    def unset_all
      @buffer.bytesize.times { |index| @buffer.setbyte(index, 0x00) }
    end

    # Performs an in-place union with another bitset.
    # This bitset will contain all bits that are set in either bitset.
    #
    # @param other [Bitz::Set] the bitset to union with
    # @return [self] returns self for method chaining
    # @raise [ArgumentError] if the bitsets have different capacities
    def set_union other
      # Raise exception if capacities don't match
      if other.capacity != capacity
        raise ArgumentError, "Cannot union bitsets with different capacities: #{capacity} != #{other.capacity}"
      end

      # Perform bitwise OR with each byte
      other_buffer = other.buffer
      other_buffer.each_byte.with_index do |byte, index|
        current = @buffer.getbyte(index)
        @buffer.setbyte(index, current | byte)
      end

      self
    end

    # Performs an in-place intersection with another bitset.
    # This bitset will contain only bits that are set in both bitsets.
    #
    # @param other [Bitz::Set] the bitset to intersect with
    # @return [self] returns self for method chaining
    # @raise [ArgumentError] if the bitsets have different capacities
    def set_intersection other
      # Raise exception if capacities don't match
      if other.capacity != capacity
        raise ArgumentError, "Cannot intersect bitsets with different capacities: #{capacity} != #{other.capacity}"
      end

      # Perform bitwise AND with each byte
      other_buffer = other.buffer
      other_buffer.each_byte.with_index do |byte, index|
        current = @buffer.getbyte(index)
        @buffer.setbyte(index, current & byte)
      end

      self
    end

    # Returns a new bitset containing the intersection of this bitset and another.
    # Neither original bitset is modified.
    #
    # @param other [Bitz::Set] the bitset to intersect with
    # @return [Bitz::Set] a new bitset with the intersection result
    # @raise [ArgumentError] if the bitsets have different capacities
    def & other
      dup.set_intersection other
    end

    # Returns a new bitset containing the union of this bitset and another.
    # Neither original bitset is modified.
    #
    # @param other [Bitz::Set] the bitset to union with
    # @return [Bitz::Set] a new bitset with the union result
    # @raise [ArgumentError] if the bitsets have different capacities
    def | other
      dup.set_union other
    end

    # Returns a new bitset with all bits flipped (complement/NOT operation).
    # The original bitset is not modified.
    #
    # @return [Bitz::Set] a new bitset with all bits flipped
    def !
      dup.toggle_all
    end

    # Flips all bits in the bitset (complement/NOT operation).
    # All 0 bits become 1, and all 1 bits become 0.
    #
    # @return [self] returns self for method chaining
    def toggle_all
      idx = 0
      @buffer.each_byte do |byte|
        @buffer.setbyte(idx, ~byte & 0xFF)
        idx += 1
      end
      self
    end

    # Compares this bitset with another for equality.
    # Returns false if the bitsets have different capacities.
    # Otherwise compares all bytes for exact equality.
    #
    # @param other [Object] the object to compare with
    # @return [Boolean] true if bitsets are equal, false otherwise
    def == other
      return false unless other.is_a?(self.class)
      return false unless other.capacity == capacity

      @buffer == other.buffer
    end

    protected

    attr_reader :buffer

    private

    def resize newlen, fill
      @buffer << ((fill ? "\xFF" : "\0").b * (newlen - @buffer.bytesize))
    end

    def popcount n
      n = n - ((n >> 1) & 0x55)         # 01010101 - count adjacent pairs
      n = (n & 0x33) + ((n >> 2) & 0x33) # 00110011 - count nibbles
      n = (n + (n >> 4)) & 0x0F          # 00001111 - count whole byte
      n
    end

  end
end
