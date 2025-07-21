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
    def ~
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

    # Iterates over each set bit in the bitset, yielding the bit position.
    # Only bits that are set to 1 are yielded. Bits are yielded in ascending order.
    # Returns an Enumerator if no block is given.
    #
    # @yield [Integer] the position of each set bit (0-indexed)
    # @return [Enumerator, self] returns Enumerator if no block given, otherwise self
    # @example
    #   bitset = Bitz::Set.new
    #   bitset.set(2)
    #   bitset.set(5)
    #   bitset.set(10)
    #   bitset.each_bit { |bit| puts bit }  # prints 2, 5, 10
    #   bitset.each_bit.to_a                # => [2, 5, 10]
    def each_bit
      return enum_for(__method__) unless block_given?

      byte = 0
      @buffer.each_byte { |b|
        8.times { |bit|
          if b & 0x1 == 0x1
            yield byte + bit
          end
          b >>= 1
        }
        byte += 8
      }
    end

    # Returns an ASCII art representation of the bitset.
    # Displays bit indices (in hexadecimal) on top and bit values on bottom in a table format.
    # Groups bits by bytes (8 bits) with visual separators.
    #
    # @param width [Integer] number of bits to display per row (default: 64)
    # @param start [Integer] starting bit position to display (default: 0)
    # @return [String] formatted ASCII art table
    # @example
    #   bitset = Bitz::Set.new(16)
    #   bitset.set(1)
    #   bitset.set(5)
    #   bitset.set(10)
    #   puts bitset.to_ascii(width: 16)
    #   # Output:
    #   # Bit Index: |  0  1  2  3  4  5  6  7 |  8  9  a  b  c  d  e  f |
    #   # Bit Value: |  0  1  0  0  0  1  0  0 |  0  0  1  0  0  0  0  0 |
    #   #            +------------------------+------------------------+
    def to_ascii width: 64, start: 0
      lines = []
      end_bit = [start + width, capacity].min
      total_bits = end_bit - start

      return "Empty bitset\n" if total_bits <= 0

      # Calculate number of byte groups
      byte_groups = (total_bits + 7) / 8

      # Build index line
      index_line = "Bit Index: "
      value_line = "Bit Value: "
      border_line = "           "

      byte_groups.times do |group|
        group_start = start + (group * 8)
        group_end = [group_start + 8, end_bit].min

        index_line += "|"
        value_line += "|"
        border_line += "+"

        (group_start...group_end).each do |bit_pos|
          index_line += sprintf("%3x", bit_pos)
          value_line += sprintf("%3d", set?(bit_pos) ? 1 : 0)
          border_line += "---"
        end

        # Pad incomplete byte groups
        if group_end - group_start < 8
          padding = 8 - (group_end - group_start)
          index_line += "   " * padding
          value_line += "   " * padding
          border_line += "---" * padding
        end

        index_line += " "
        value_line += " "
        border_line += "-"
      end

      index_line += "|\n"
      value_line += "|\n"
      border_line += "+\n"

      lines << index_line
      lines << value_line
      lines << border_line

      # Handle multi-row output for large bitsets
      if end_bit < capacity && width < capacity
        remaining = capacity - end_bit
        if remaining > 0
          lines << to_ascii(width: width, start: end_bit)
        end
      end

      lines.join
    end

    # Ruby's pp library integration.
    # Called by pp when pretty printing this object.
    #
    # @param pp [PP] the pretty printer object
    # @return [void]
    def pretty_print pp
      pp.text(to_ascii(width: 32))
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

    alias :eql? :==

    def hash
      @buffer.hash
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
