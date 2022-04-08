# This example demonstrates 
# Design Pattern: Chain of Responsibility
# from https://github.com/RefactoringGuru/design-patterns-ruby
# SOLID Principles: Dependency Inversion
# from https://github.com/bodrovis-learning/Ruby-SOLID-video

# Data sources
PRICE_LIST_1 = {
  A: 100.0,
  B: 101.0,
  C: 102.0,
  D: 103.0,
  E: 104.0,
  F: 105.0,
  G: 106.0,
  H: 107.0,
  I: 108.0,
  J: 109.0,
  K: 110.0,
  L: 111.0,
  M: 112.0
}

PRICE_LIST_2 = {
  A: 0.1000,
  O: 0.1010,
  P: 0.1020,
  Q: 0.1030,
  R: 0.1040,
  S: 0.1050,
  T: 0.1060,
  U: 0.1070,
  W: 0.1080,
  V: 0.1090,
  X: 0.1100,
  Y: 0.1110,
  Z: 0.1120
}

# Code library
class Array
  def delete_elements(ary)
    ary.each do |x|
      if index = index(x)
        delete_at(index)
      end
    end
  end
end


class Basket
  # Important: total discount calculation in fractions
  @@ary = []
  @@price_list = {}

  def self.new(ary: [], price_list: {})
    @@price_list = price_list
    k = price_list.keys
    # Exclude unsold goods
    @@ary = ary.find_all{|i| k.include?(i)}
  end

  def self.show
    @@ary
  end

  def self.calculate_and_take_out(basket_list: [], discount: 0)
    result = basket_list.reduce(0) do |res, v| 
      res + (@@price_list[v] || 0) * (1.0 - discount)
    end || 0
    @@ary.delete_elements(basket_list)
    result
  end

  def self.calculate_and_empty_the_basket
    result = @@ary.reduce(0) do |res, v| 
      res + (@@price_list[v] || 0)
    end || 0
    @@ary.clear
    result
  end
end

# Using different price list sources
class Basket_1 < Basket
  def self.new(ary:, price_list: PRICE_LIST_1)
    super(ary: ary, price_list: price_list)
  end
end

class Basket_2 < Basket
  def self.new(ary:, price_list: PRICE_LIST_2)
    super(ary: ary, price_list: price_list)
  end
end


class DiscountRule
  def next_discountable=(_rule)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def discount(_basket)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  private

  def is_defined?(result)
    defined?(result) && !result.nil?  && !result.zero?
  end
end

class AbstractDiscountRule < DiscountRule
  attr_writer :next_discountable

  def next_discountable(rule)
    @next_discountable = rule

    rule
  end

  def discount(basket)
    return @next_discountable.discount(basket) if @next_discountable

    0
  end
end

# Если одновременно выбраны А и B,
# то их суммарная стоимость уменьшается на 10% (для каждой пары А и B)
class DiscountRule1 < AbstractDiscountRule
  DISC_ARR = %i[A B]
  DISC_PRCNT = 10.0/100

  def discount(basket)
    result = 0
    while (DISC_ARR & basket.show).size == 2
      result += basket.calculate_and_take_out(basket_list: DISC_ARR, discount: DISC_PRCNT)
    end
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если одновременно выбраны D и E,
# то их суммарная стоимость уменьшается на 5% (для каждой пары D и E)
class DiscountRule2 < AbstractDiscountRule
  DISC_ARR = %i[D E]
  DISC_PRCNT = 5.0/100

  def discount(basket)
    result = 0
    while (DISC_ARR & basket.show).size == 2
      result += basket.calculate_and_take_out(basket_list: DISC_ARR, discount: DISC_PRCNT)
    end
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если одновременно выбраны E,F,G,
# то их суммарная стоимость уменьшается на 5% (для каждой тройки E,F,G)
class DiscountRule3 < AbstractDiscountRule
  DISC_ARR = %i[E F G]
  DISC_PRCNT = 5.0/100

  def discount(basket)
    result = 0
    while (DISC_ARR & basket.show).size == 3
      result += basket.calculate_and_take_out(basket_list: DISC_ARR, discount: DISC_PRCNT)
    end
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если одновременно выбраны А и один из [K,L,M],
# то стоимость выбранного продукта уменьшается на 5%
class DiscountRule4 < AbstractDiscountRule
  DISC_BASE = %i[A]
  DISC_ADD = %i[K L M]
  DISC_PRCNT = 5.0/100

  def discount(basket)
    result = 0
    ex_arr = DISC_ADD
    while ex_arr.any?
      break unless basket.show.include?(DISC_BASE.first)
      rnd_elem = ex_arr.sample
      if basket.show.include?(rnd_elem)
        add_arr = DISC_BASE + [rnd_elem]
        result += basket.calculate_and_take_out(basket_list: add_arr, discount: DISC_PRCNT)
      else
        ex_arr.delete(rnd_elem)
      end
    end
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если пользователь выбрал одновременно 5 продуктов или больше кроме A и C,
# то он получает скидку 20% от суммы заказа
class DiscountRule5 < AbstractDiscountRule
  NON_DISC_ARR = %i[A C]
  DISC_PRCNT = 20.0/100

  def discount(basket)
    result = 0
    disc_arr = basket.show - NON_DISC_ARR
    result += basket.calculate_and_take_out(basket_list: disc_arr, discount: DISC_PRCNT) if disc_arr.size > 4
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если пользователь выбрал одновременно 4 продукта кроме A и C,
# то он получает скидку 10% от суммы заказа
class DiscountRule6 < AbstractDiscountRule
  NON_DISC_ARR = %i[A C]
  DISC_PRCNT = 10.0/100

  def discount(basket)
    result = 0
    disc_arr = basket.show - NON_DISC_ARR
    result += basket.calculate_and_take_out(basket_list: disc_arr, discount: DISC_PRCNT) if disc_arr.size > 3
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# Если пользователь выбрал одновременно 3 продукта кроме A и C,
# то он получает скидку 5% от суммы заказа
class DiscountRule7 < AbstractDiscountRule
  NON_DISC_ARR = %i[A C]
  DISC_PRCNT = 5.0/100

  def discount(basket)
    result = 0
    disc_arr = basket.show - NON_DISC_ARR
    result += basket.calculate_and_take_out(basket_list: disc_arr, discount: DISC_PRCNT) if disc_arr.size > 2
    p(self.class.name) if is_defined?(result)
    result += super(basket)
  end
end

# User code
def calculate_total_with_discount(discountable, basket)
  result = discountable.discount(basket)
  result += basket.calculate_and_empty_the_basket
  if result > 0
    print "Sold for #{result.round(2)}"
  else
    print "Nothing has been sold"
  end
end

rule_1 = DiscountRule1.new
rule_2 = DiscountRule2.new
rule_3 = DiscountRule3.new
rule_4 = DiscountRule4.new
rule_5 = DiscountRule5.new
rule_6 = DiscountRule6.new
rule_7 = DiscountRule7.new

rule_1.next_discountable(rule_2)
      .next_discountable(rule_3)
      .next_discountable(rule_4)
      .next_discountable(rule_5)
      .next_discountable(rule_6)
      .next_discountable(rule_7)

puts "Tests:\n\n"

Basket_1.new(ary: %i[A B])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 180.9
puts "\n\n"

Basket_1.new(ary: %i[A B A B A B])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 542.7
puts "\n\n"

Basket_1.new(ary: %i[D E])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 196.65
puts "\n\n"

Basket_1.new(ary: %i[D E D E])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 393.3
puts "\n\n"

Basket_1.new(ary: %i[E F G])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 299.25
puts "\n\n"

Basket_1.new(ary: %i[E F G E F G])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 598.5
puts "\n\n"

Basket_1.new(ary: %i[A K L M])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = [422.5;422.45;422.4] (random variable out of three possible)
puts "\n\n"

Basket_1.new(ary: %i[A K L M A K L M])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = ? (block 4 fires twice and block 6 fires once) 
puts "\n\n"

Basket_1.new(ary: %i[I J K])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 310.65 
puts "\n\n"

Basket_1.new(ary: %i[I J K L])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 394.2 
puts "\n\n"

Basket_1.new(ary: %i[I J K L M])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
# = 440.0 
puts "\n\n"

puts "Random sets of baskets for sale:\n\n"

Basket_1.new(ary: %i[A B C D E I J K L M W Z A B A])
puts 'Basket_1:'
calculate_total_with_discount(rule_1, Basket_1)
puts "\n\n"

Basket_2.new(ary: %i[A B C D E I J K L M W Z A B A])
puts 'Basket_2:'
calculate_total_with_discount(rule_1, Basket_2)
puts "\n\n"
