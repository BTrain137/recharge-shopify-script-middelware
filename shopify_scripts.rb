# Set empty children_products hash

bundle_groups = {}


# Loop over all items in cart to find parent bundle and create bundle_groups hash
def getProductIds(product, group)
  ids = []
  for tag in product.tags
    if tag.include?(group)
      id = tag.split('::').last
      ids.push(id)
    end
  end
  return ids
end

Input.cart.line_items.each do |line_item|
  product = line_item.variant.product
  next if line_item.properties["bundle_id"].nil? or line_item.properties["bundle_type"] != "parent"
  bundle_id = line_item.properties["bundle_id"]
  bundle_groups["#{bundle_id}"] = {}

  for tag in product.tags
    if tag.include?("_qty::")
      bundle_group = tag.split("_qty::").first
      _tag = tag.split("::")

      bundle_groups["#{bundle_id}"]["#{bundle_group}"] = {
        "qty" => _tag.last.to_i,
        "ids" => getProductIds(product, "#{bundle_group}_id")
      }
    end
  end
end


# Loop over all items again to apply available child product discounts
Input.cart.line_items.each do |line_item|
  product = line_item.variant.product
  next if line_item.properties["bundle_id"].nil?

  product_id = product.id.to_s
  
  bundle_groups.keys.each do |key|
    next unless key === line_item.properties["bundle_id"].to_s

    bundle_id = line_item.properties["bundle_id"]
    bundle_groups["#{bundle_id}"].keys.each do |key|
      group = bundle_groups["#{bundle_id}"][key]

      if group["ids"].include?(product_id)
        qty = group["qty"]

        if qty > 0
          if line_item.quantity > qty
            new_line_item = line_item.split(take: qty)
            new_line_item.change_line_price(Money.new(cents: 0), message: "Included")
            Input.cart.line_items << new_line_item
            quantity_removed = qty
          else
            line_item.change_line_price(Money.new(cents: 0), message: "Included")
            quantity_removed = line_item.quantity
          end

          bundle_groups["#{bundle_id}"][key]["qty"] = bundle_groups["#{bundle_id}"][key]["qty"] - quantity_removed
        end
      end
    end
  end
end

PRODUCT_DISCOUNT_TIERS = [
  {
    product_selector_match_type: :include,
    product_selector_type: :sku_unit_size,
    product_selectors: ["subscription"],
    tiers: [
      {
        unit_size: 1,
        discount_type: :exact,
        discount_amount: 14.95,
        discount_message: 'Price Per Bar $2.99',
      },
      {
        unit_size: 2,
        discount_type: :exact,
        discount_amount: 14.95,
        discount_message: 'Price Per Bar $2.99',
      },
      {
        unit_size: 3,
        discount_type: :exact,
        discount_amount: 12.65,
        discount_message: 'Saved 15% Price Per Bar $2.53',
      },
      {
        unit_size: 4,
        discount_type: :exact,
        discount_amount: 12.70,
        discount_message: 'Saved 15% Price Per Bar $2.54',
      },
      {
        unit_size: 5,
        discount_type: :exact,
        discount_amount: 12.70,
        discount_message: 'Saved 15% Price Per Bar $2.54',
      },
      {
        unit_size: 6,
        discount_type: :exact,
        discount_amount: 11.16,
        discount_message: 'Saved 25% Price Per Bar $2.23',
      },
      {
        unit_size: 7,
        discount_type: :exact,
        discount_amount: 11.21,
        discount_message: 'Saved 25% Price Per Bar $2.24',
      },
      {
        unit_size: 8,
        discount_type: :exact,
        discount_amount: 11.21,
        discount_message: 'Saved 25% Price Per Bar $2.24',
      },
      {
        unit_size: 9,
        discount_type: :exact,
        discount_amount: 11.21,
        discount_message: 'Saved 25% Price Per Bar $2.24',
      },
      {
        unit_size: 10,
        discount_type: :exact,
        discount_amount: 10.49,
        discount_message: 'Saved 30% Price Per Bar $2.10',
      },
      {
        unit_size: 11,
        discount_type: :exact,
        discount_amount: 10.46,
        discount_message: 'Saved 30% Price Per Bar $2.09',
      },
      {
        unit_size: 12,
        discount_type: :exact,
        discount_amount: 10.41,
        discount_message: 'Saved 30% Price Per Bar $2.08',
      },
    ],
  },
]

# ================================ Script Code (do not edit) ================================
# ================================================================
# ProductSelector
#
# Finds matching products by the entered criteria.
# ================================================================
class ProductSelector
  def initialize(match_type, selector_type, selectors)
    @match_type = match_type
    @comparator = match_type == :include ? 'any?' : 'none?'
    @selector_type = selector_type
    @selectors = selectors
  end

  def match?(line_item)
    if self.respond_to?(@selector_type)
      self.send(@selector_type, line_item)
    else
      raise RuntimeError.new('Invalid product selector type')
    end
  end

  def sku_unit_size(line_item)
    product_type = line_item.variant.product.product_type;
    product_tags = line_item.variant.product.tags.map { |tag| tag.downcase.strip }
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    skus = line_item.variant.skus[0]
    total_bars = skus.split("/")[2];

    if total_bars
      total_bars = total_bars.to_i
      is_total_bars = total_bars.is_a? Integer
  
      if is_total_bars && product_type == "2022"
        (@selectors & product_tags).send(@comparator)
      end
    end
  end
end

# ================================================================
# DiscountApplicator
#
# Applies the entered discount to the supplied line item.
# ================================================================
class DiscountApplicator
  def initialize(discount_type, discount_amount, discount_message)
    @discount_type = discount_type
    @discount_message = discount_message

    @discount_amount = if discount_type == :percent
      1 - (discount_amount * 0.01)
    else
      Money.new(cents: 100) * discount_amount
    end
  end

  def apply(line_item)
    new_line_price = if @discount_type == :percent
      line_item.line_price * @discount_amount
    elsif @discount_type == :exact
      @discount_amount * line_item.quantity
    else
      [line_item.line_price - (@discount_amount * line_item.quantity), Money.zero].max
    end

    line_item.change_line_price(new_line_price, message: @discount_message)
  end
end

# ================================================================
# TieredProductDiscountByQuantityCampaign
#
# If the total quantity of matching items is greater than (or
# equal to) an entered threshold, the associated discount is
# applied to each matching item.
# ================================================================
class TieredProductDiscountByQuantityCampaign
  def initialize(campaigns)
    @campaigns = campaigns
  end

  def run(cart)
    @campaigns.each do |campaign|
      product_selector = ProductSelector.new(
        campaign[:product_selector_match_type],
        campaign[:product_selector_type],
        campaign[:product_selectors],
      )

      applicable_items = cart.line_items.select { |line_item| product_selector.match?(line_item) }

      next if applicable_items.nil?

      cart_total_bars = applicable_items.reduce(0) { | sum, line_item | 
        skus = line_item.variant.skus[0];
        total_bars = skus.split("/")[2].to_i;
        sum + (total_bars * line_item.quantity);
      }

      cart_total_unit = cart_total_bars / 5;

      tiers = campaign[:tiers].sort_by { |tier| tier[:unit_size] }.reverse
      applicable_tier = tiers.find { |tier| tier[:unit_size] <= cart_total_unit }

      next if applicable_tier.nil?

      discount_applicator = DiscountApplicator.new(
        applicable_tier[:discount_type],
        applicable_tier[:discount_amount],
        applicable_tier[:discount_message]
      )

      applicable_items.each do |line_item|
        discount_applicator.apply(line_item)
      end
    end
  end
end


#
# Rebuy Upsell Discount
#

# Campaign - Dynamic Discounts
class RebuyDynamicDiscount
  def initialize(discount_type, discount_amount, success_message)
    @discount_type = discount_type
    @discount_amount = discount_amount
    @success_message = success_message
  end

  def run(cart)
    cart.line_items.each do |line_item|
      next if line_item.properties["_UpsellSource"].nil? or line_item.properties["_UpsellSource"] != "Rebuy"

      if !line_item.properties["_UpsellDiscount"].nil?
        @discount_amount = line_item.properties["_UpsellDiscount"].to_i
      end

      discount = (Money.new(cents: 0))

      if @discount_type == 'percentage'
        discount = (line_item.line_price * (@discount_amount / 100))
      elsif @discount_type == 'fixed'
        discount = (Money.new(cents: 100) * @discount_amount)
      end

      line_item.change_line_price(line_item.line_price - discount, message: @success_message)
    end
  end
end


CAMPAIGNS = [
  RebuyDynamicDiscount.new('percentage', 10, 'Limited-Time Offer'),
  TieredProductDiscountByQuantityCampaign.new(PRODUCT_DISCOUNT_TIERS),
]

# Run each campaign
CAMPAIGNS.each do |campaign|
  campaign.run(Input.cart)
end


Output.cart = Input.cart
