require 'test_helper'

class BitzSetTest < Minitest::Test
  def setup
    @set = Bitz::Set.new
  end

  def test_each_bit
    @set.set 2
    @set.set 3
    @set.set 10

    list = []
    @set.each_bit { |b| list << b }
    assert_equal [2, 3, 10], list
    assert_equal [2, 3, 10], @set.each_bit.to_a
  end

  def test_hash_eql
    other = @set.dup
    assert_equal @set.hash, other.hash
    assert @set.eql?(other)
  end

  def test_count
    assert_equal 0, @set.count

    @set.set(5)
    assert_equal 1, @set.count

    @set.set(16)
    assert_equal 2, @set.count
  end

  def test_capacity
    assert_equal 64, @set.capacity
  end

  def test_dup
    @set.set(5)
    assert @set.set?(5)

    new = @set.dup
    assert new.set?(5)
    new.set(6)
    assert new.set?(6)
    refute @set.set?(6)
  end

  def test_set_and_check_bit
    @set.set(5)
    assert @set.set?(5)
  end

  def test_unset_bit
    @set.set(5)
    @set.unset(5)
    refute @set.set?(5)
  end

  def test_unset_bit_returns_nil_for_uninitialized
    assert_nil @set.set?(100)
  end

  def test_dynamic_buffer_growth
    @set.set(100)
    assert @set.set?(100)
  end

  def test_custom_initial_size
    set = Bitz::Set.new(128)
    set.set(50)
    assert set.set?(50)
  end

  def test_multiple_bits
    [1, 5, 10, 63, 100].each { |bit| @set.set(bit) }
    [1, 5, 10, 63, 100].each { |bit| assert @set.set?(bit) }
  end

  def test_set_all
    @set.set_all
    (0..63).each { |bit| assert @set.set?(bit) }
  end

  def test_unset_all
    @set.set(5)
    @set.set(10)
    @set.set(50)
    @set.unset_all
    (0..63).each { |bit| refute @set.set?(bit) }
  end

  def test_set_all_then_unset_all
    @set.set_all
    @set.unset_all
    (0..63).each { |bit| refute @set.set?(bit) }
  end

  def test_set_union_basic
    other = Bitz::Set.new
    @set.set(5)
    other.set(10)

    @set.set_union(other)

    assert @set.set?(5)
    assert @set.set?(10)
  end

  def test_set_union_overlapping
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(15)

    @set.set_union(other)

    assert @set.set?(5)
    assert @set.set?(10)
    assert @set.set?(15)
  end

  def test_set_union_different_sizes_raises_error
    other = Bitz::Set.new(128)
    @set.set(5)
    other.set(100)

    error = assert_raises(ArgumentError) do
      @set.set_union(other)
    end

    assert_match(/Cannot union bitsets with different capacities/, error.message)
    assert_match(/64 != 128/, error.message)
  end

  def test_set_union_returns_self
    other = Bitz::Set.new
    result = @set.set_union(other)
    assert_same @set, result
  end

  def test_set_union_count
    other = Bitz::Set.new
    @set.set(1)
    @set.set(3)
    other.set(2)
    other.set(3)

    @set.set_union(other)

    assert_equal 3, @set.count # bits 1, 2, 3 are set
  end

  def test_set_intersection_basic
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(15)

    @set.set_intersection(other)

    assert @set.set?(5)
    refute @set.set?(10)
    refute @set.set?(15)
  end

  def test_set_intersection_no_overlap
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(15)
    other.set(20)

    @set.set_intersection(other)

    refute @set.set?(5)
    refute @set.set?(10)
    refute @set.set?(15)
    refute @set.set?(20)
  end

  def test_set_intersection_all_overlap
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(10)

    @set.set_intersection(other)

    assert @set.set?(5)
    assert @set.set?(10)
  end

  def test_set_intersection_different_sizes_raises_error
    other = Bitz::Set.new(128)
    @set.set(5)
    other.set(5)

    error = assert_raises(ArgumentError) do
      @set.set_intersection(other)
    end

    assert_match(/Cannot intersect bitsets with different capacities/, error.message)
    assert_match(/64 != 128/, error.message)
  end

  def test_set_intersection_returns_self
    other = Bitz::Set.new
    result = @set.set_intersection(other)
    assert_same @set, result
  end

  def test_set_intersection_count
    other = Bitz::Set.new
    @set.set(1)
    @set.set(2)
    @set.set(3)
    other.set(2)
    other.set(3)
    other.set(4)

    @set.set_intersection(other)

    assert_equal 2, @set.count # bits 2, 3 are set
  end

  def test_ampersand_basic
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(15)

    result = @set & other

    # Original bitsets unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    assert other.set?(5)
    assert other.set?(15)

    # Result has intersection
    assert result.set?(5)
    refute result.set?(10)
    refute result.set?(15)
  end

  def test_ampersand_no_overlap
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(15)
    other.set(20)

    result = @set & other

    # Original bitsets unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    assert other.set?(15)
    assert other.set?(20)

    # Result is empty
    refute result.set?(5)
    refute result.set?(10)
    refute result.set?(15)
    refute result.set?(20)
    assert_equal 0, result.count
  end

  def test_ampersand_all_overlap
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(10)

    result = @set & other

    # Original bitsets unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    assert other.set?(5)
    assert other.set?(10)

    # Result has all bits
    assert result.set?(5)
    assert result.set?(10)
    assert_equal 2, result.count
  end

  def test_ampersand_different_sizes_raises_error
    other = Bitz::Set.new(128)
    @set.set(5)
    other.set(5)

    error = assert_raises(ArgumentError) do
      @set & other
    end

    assert_match(/Cannot intersect bitsets with different capacities/, error.message)
    assert_match(/64 != 128/, error.message)
  end

  def test_ampersand_returns_new_instance
    other = Bitz::Set.new
    result = @set & other

    refute_same @set, result
    refute_same other, result
    assert_instance_of Bitz::Set, result
    assert_equal @set.capacity, result.capacity
  end

  def test_pipe_basic
    other = Bitz::Set.new
    @set.set(5)
    other.set(10)

    result = @set | other

    # Original bitsets unchanged
    assert @set.set?(5)
    refute @set.set?(10)
    refute other.set?(5)
    assert other.set?(10)

    # Result has union
    assert result.set?(5)
    assert result.set?(10)
  end

  def test_pipe_overlapping
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(15)

    result = @set | other

    # Original bitsets unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    refute @set.set?(15)
    assert other.set?(5)
    refute other.set?(10)
    assert other.set?(15)

    # Result has union
    assert result.set?(5)
    assert result.set?(10)
    assert result.set?(15)
    assert_equal 3, result.count
  end

  def test_pipe_no_bits_set
    other = Bitz::Set.new

    result = @set | other

    # Original bitsets unchanged (both empty)
    assert_equal 0, @set.count
    assert_equal 0, other.count

    # Result is empty
    assert_equal 0, result.count
  end

  def test_pipe_different_sizes_raises_error
    other = Bitz::Set.new(128)
    @set.set(5)
    other.set(100)

    error = assert_raises(ArgumentError) do
      @set | other
    end

    assert_match(/Cannot union bitsets with different capacities/, error.message)
    assert_match(/64 != 128/, error.message)
  end

  def test_pipe_returns_new_instance
    other = Bitz::Set.new
    result = @set | other

    refute_same @set, result
    refute_same other, result
    assert_instance_of Bitz::Set, result
    assert_equal @set.capacity, result.capacity
  end

  def test_pipe_count
    other = Bitz::Set.new
    @set.set(1)
    @set.set(3)
    other.set(2)
    other.set(3)

    result = @set | other

    # Original bitsets unchanged
    assert_equal 2, @set.count
    assert_equal 2, other.count

    # Result has union count
    assert_equal 3, result.count # bits 1, 2, 3 are set
  end

  def test_bang_basic
    @set.set(5)
    @set.set(10)

    result = !@set

    # Original bitset unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    assert_equal 2, @set.count

    # Result has all bits flipped
    refute result.set?(5)
    refute result.set?(10)
    assert result.set?(0)
    assert result.set?(1)
    assert result.set?(15)
    assert result.set?(63)
    assert_equal 62, result.count # 64 - 2 set bits
  end

  def test_bang_empty_set
    result = !@set

    # Original bitset unchanged (empty)
    assert_equal 0, @set.count

    # Result has all bits set
    (0...64).each { |bit| assert result.set?(bit) }
    assert_equal 64, result.count
  end

  def test_bang_full_set
    @set.set_all

    result = !@set

    # Original bitset unchanged (full)
    assert_equal 64, @set.count

    # Result has no bits set
    (0...64).each { |bit| refute result.set?(bit) }
    assert_equal 0, result.count
  end

  def test_bang_returns_new_instance
    result = !@set

    refute_same @set, result
    assert_instance_of Bitz::Set, result
    assert_equal @set.capacity, result.capacity
  end

  def test_bang_double_negation
    @set.set(5)
    @set.set(10)
    @set.set(20)

    result = !!@set

    # Double negation should restore original
    assert result.set?(5)
    assert result.set?(10)
    assert result.set?(20)
    assert_equal 3, result.count

    # Original unchanged
    assert @set.set?(5)
    assert @set.set?(10)
    assert @set.set?(20)
    assert_equal 3, @set.count
  end

  def test_bang_specific_capacity
    small_set = Bitz::Set.new(16)
    small_set.set(3)
    small_set.set(7)

    result = !small_set

    # Check capacity preserved
    assert_equal 16, result.capacity

    # Check specific bits flipped correctly
    refute result.set?(3)
    refute result.set?(7)
    assert result.set?(0)
    assert result.set?(15)
    assert_equal 14, result.count # 16 - 2 set bits
  end

  def test_toggle_all_basic
    @set.set(5)
    @set.set(10)
    @set.set(20)
    initial_count = @set.count

    result = @set.toggle_all

    # Returns self for chaining
    assert_same @set, result

    # All previously set bits are now unset
    refute @set.set?(5)
    refute @set.set?(10)
    refute @set.set?(20)

    # All previously unset bits are now set
    assert @set.set?(0)
    assert @set.set?(1)
    assert @set.set?(15)
    assert @set.set?(63)

    # Count is complement of original
    assert_equal 64 - initial_count, @set.count
  end

  def test_toggle_all_empty_set
    initial_count = @set.count
    assert_equal 0, initial_count

    @set.toggle_all

    # All bits should now be set
    (0...64).each { |bit| assert @set.set?(bit) }
    assert_equal 64, @set.count
  end

  def test_toggle_all_full_set
    @set.set_all
    initial_count = @set.count
    assert_equal 64, initial_count

    @set.toggle_all

    # All bits should now be unset
    (0...64).each { |bit| refute @set.set?(bit) }
    assert_equal 0, @set.count
  end

  def test_toggle_all_double_toggle
    @set.set(5)
    @set.set(10)
    @set.set(20)
    original_bits = [5, 10, 20]
    original_count = @set.count

    @set.toggle_all.toggle_all

    # Should restore original state
    original_bits.each { |bit| assert @set.set?(bit) }
    assert_equal original_count, @set.count

    # Check some bits that should still be unset
    refute @set.set?(0)
    refute @set.set?(1)
    refute @set.set?(15)
  end

  def test_toggle_all_specific_capacity
    small_set = Bitz::Set.new(16)
    small_set.set(3)
    small_set.set(7)
    initial_count = small_set.count

    small_set.toggle_all

    # Check capacity unchanged
    assert_equal 16, small_set.capacity

    # Check specific bits flipped
    refute small_set.set?(3)
    refute small_set.set?(7)
    assert small_set.set?(0)
    assert small_set.set?(15)

    # Check count
    assert_equal 16 - initial_count, small_set.count
  end

  def test_toggle_all_method_chaining
    other = Bitz::Set.new
    other.set(1)

    @set.set(5)
    result = @set.toggle_all.set_union(other)

    # Should be chainable and return self
    assert_same @set, result

    # Verify final state - bit 5 was set then toggled (now unset), bit 1 added via union
    refute @set.set?(5) # was set then toggled
    assert @set.set?(1) # added via union
    assert @set.set?(0) # was unset then toggled
  end

  def test_equality_identical_empty_sets
    other = Bitz::Set.new

    assert_equal @set, other
    assert_equal other, @set
  end

  def test_equality_identical_sets_with_bits
    other = Bitz::Set.new
    @set.set(5)
    @set.set(10)
    other.set(5)
    other.set(10)

    assert_equal @set, other
    assert_equal other, @set
  end

  def test_equality_different_bits
    other = Bitz::Set.new
    @set.set(5)
    other.set(10)

    refute_equal @set, other
    refute_equal other, @set
  end

  def test_equality_different_capacities
    other = Bitz::Set.new(128)

    refute_equal @set, other
    refute_equal other, @set
  end

  def test_equality_different_capacities_same_bits
    other = Bitz::Set.new(128)
    @set.set(5)
    other.set(5)

    refute_equal @set, other
    refute_equal other, @set
  end

  def test_equality_same_capacity_different_patterns
    other = Bitz::Set.new(64)
    @set.set(1)
    @set.set(3)
    @set.set(5)
    other.set(2)
    other.set(4)
    other.set(6)

    refute_equal @set, other
    refute_equal other, @set
  end

  def test_equality_full_sets
    other = Bitz::Set.new(64)
    @set.set_all
    other.set_all

    assert_equal @set, other
    assert_equal other, @set
  end

  def test_equality_one_full_one_partial
    other = Bitz::Set.new(64)
    @set.set_all
    other.set(5)

    refute_equal @set, other
    refute_equal other, @set
  end

  def test_equality_with_non_bitset_object
    refute_equal @set, "not a bitset"
    refute_equal @set, 42
    refute_equal @set, nil
    refute_equal @set, []
  end

  def test_equality_after_operations
    other = Bitz::Set.new
    @set.set(5)
    other.set(5)

    # Initially equal
    assert_equal @set, other

    # After toggle_all, should be equal
    @set.toggle_all
    other.toggle_all
    assert_equal @set, other

    # After different operations, should not be equal
    # Set bit 5 in @set only (bit 5 was originally set, so after toggle it's unset)
    @set.set(5)
    refute_equal @set, other
  end

  def test_equality_with_duplicated_sets
    @set.set(1)
    @set.set(15)
    @set.set(63)

    copy = @set.dup
    assert_equal @set, copy

    # Modify copy
    copy.set(30)
    refute_equal @set, copy
  end

  def test_to_ascii_basic
    @set.set(1)
    @set.set(5)
    @set.set(10)

    output = @set.to_ascii(width: 16)

    # Should contain bit indices
    assert_match(/Bit Index:/, output)
    assert_match(/Bit Value:/, output)

    # Should contain specific bit positions
    assert_match(/\s+1\s+/, output)
    assert_match(/\s+5\s+/, output)
    assert_match(/\s+10\s+/, output)

    # Should have proper formatting with separators
    assert_match(/\|/, output)
    assert_match(/\+/, output)
  end

  def test_to_ascii_empty_set
    output = @set.to_ascii(width: 16)

    # Should show all zeros in the value line
    lines = output.split("\n")
    value_line = lines.find { |line| line.start_with?("Bit Value:") }

    # Should contain only 0s in the value line (no 1s)
    assert_match(/0/, value_line)
    refute_match(/\|\s+[^0\s]/, value_line) # No non-zero values between separators

    assert_match(/Bit Index:/, output)
    assert_match(/Bit Value:/, output)
  end

  def test_to_ascii_full_set
    small_set = Bitz::Set.new(16)
    small_set.set_all

    output = small_set.to_ascii(width: 16)

    # Should show all ones for a full set
    lines = output.split("\n")
    value_line = lines.find { |line| line.start_with?("Bit Value:") }

    # Count the 1s in the value line (look for the pattern "  1")
    ones_count = value_line.scan(/\s+1(?=\s|\|)/).length
    assert_equal 16, ones_count
  end

  def test_to_ascii_custom_width
    @set.set(2)
    @set.set(10)
    @set.set(18)

    # Test with 8-bit width
    output = @set.to_ascii(width: 8)
    lines = output.split("\n")

    # Should have multiple rows for bits beyond width
    assert_operator lines.length, :>, 3

    # First row should contain bits 0-7
    assert_match(/\s+2\s+/, lines[0])
    refute_match(/\s+a\s+/, lines[0])  # 10 in hex should not be in first row
  end

  def test_to_ascii_start_offset
    @set.set(10)
    @set.set(15)
    @set.set(20)

    # Start from bit 8
    output = @set.to_ascii(width: 16, start: 8)

    # Should contain bits 8-23 (in hex: 8, a=10, f=15, 14=20)
    assert_match(/\s+a\s+/, output)  # 10 in hex
    assert_match(/\s+f\s+/, output)  # 15 in hex
    assert_match(/\s+14\s+/, output) # 20 in hex

    # Should not contain bits 0-7 in the index line
    lines = output.split("\n")
    index_line = lines[0]
    refute_match(/\|\s+0\s+/, index_line)
    refute_match(/\|\s+7\s+/, index_line)
  end

  def test_to_ascii_byte_grouping
    @set.set(7)  # End of first byte
    @set.set(8)  # Start of second byte

    output = @set.to_ascii(width: 16)

    # Should have proper byte separators
    separators = output.scan(/\|/).length
    assert_operator separators, :>, 2 # At least opening and closing separators

    # Should group by 8-bit boundaries
    lines = output.split("\n")
    index_line = lines[0]

    # Should have bit 7 and 8 in different groups visually
    assert_match(/\s+7\s+.*\|\s+8\s+/, index_line)
  end

  def test_to_ascii_large_indices
    large_set = Bitz::Set.new(128)
    large_set.set(100)
    large_set.set(127)

    output = large_set.to_ascii(width: 32, start: 96)

    # Should handle 2-digit hex indices correctly (100 = 0x64, 127 = 0x7f)
    assert_match(/64/, output) # 100 in hex
    assert_match(/7f/, output) # 127 in hex

    # Should maintain alignment
    lines = output.split("\n")
    index_line = lines[0]
    value_line = lines[1]

    # Lines should be similar length (within a few chars for borders)
    assert_in_delta index_line.length, value_line.length, 5
  end

  def test_to_ascii_edge_cases
    # Single bit set
    single_set = Bitz::Set.new(8)
    single_set.set(0)

    output = single_set.to_ascii(width: 8)
    assert_match(/Bit Index:/, output)
    assert_match(/Bit Value:/, output)

    # Empty range
    empty_output = @set.to_ascii(width: 0)
    assert_equal "Empty bitset\n", empty_output

    # Start beyond capacity
    beyond_output = @set.to_ascii(start: 1000)
    assert_equal "Empty bitset\n", beyond_output
  end

  def test_pp_integration
    require 'pp'
    require 'stringio'

    @set.set(1)
    @set.set(5)
    @set.set(10)

    # Capture pp output
    output = StringIO.new
    PP.pp(@set, output)
    result = output.string

    # Should contain the ASCII art format
    assert_match(/Bit Index:/, result)
    assert_match(/Bit Value:/, result)
    assert_match(/\s+1\s+/, result)  # 1 in hex is still 1
    assert_match(/\s+5\s+/, result)  # 5 in hex is still 5
    assert_match(/\s+a\s+/, result)  # 10 in hex is 'a'
  end
end
