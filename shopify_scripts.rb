PRODUCT_DISCOUNT_TIERS = [
  {
    product_selector_match_type: :include,
    product_selector_type: :properties,
    product_selectors: ["Build A Box"],
		product_selectors_key: "_bundle",
    tiers: [
      {
        threshold: 50,
        discount_type: :percent,
        discount_amount: 5,
        discount_message: 'Build A Box Bundle 5% OFF',
      },
      {
        threshold: 100,
        discount_type: :percent,
        discount_amount: 10,
        discount_message: 'Build A Box Bundle 10% OFF',
      },
    ],
  },
]

PRODUCT_DISCOUNT_TIERS_SUBSCRIPTION = [
  {
    product_selector_match_type: :include,
    product_selector_type: :properties,
    product_selectors: ["Build A Box Subscription"],
		product_selectors_key: "_bundle",
    tiers: [
      {
        threshold: 40,
        discount_type: :percent,
        discount_amount: 5,
        discount_message: 'Build A Box Subscription 5% OFF',
      },
      {
        threshold: 90,
        discount_type: :percent,
        discount_amount: 10,
        discount_message: 'Build A Box Subscription 10% OFF',
      },
    ],
  },
]

class ProductSelectorBA
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

  def tag(line_item)
    product_tags = line_item.variant.product.tags.map { |tag| tag.downcase.strip }
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@selectors & product_tags).send(@comparator)
  end

	# def properties(line_item)
  #   @selectors = @selectors.map { |selector| selector.downcase.strip }
  #   (@match_type == :include) == @selectors.include?(line_item.properties['_bundle'])
  # end

  def type(line_item)
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@match_type == :include) == @selectors.include?(line_item.variant.product.product_type.downcase.strip)
  end

  def vendor(line_item)
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@match_type == :include) == @selectors.include?(line_item.variant.product.vendor.downcase.strip)
  end

  def product_id(line_item)
    (@match_type == :include) == @selectors.include?(line_item.variant.product.id)
  end

  def variant_id(line_item)
    (@match_type == :include) == @selectors.include?(line_item.variant.id)
  end

  def subscription(line_item)
    !line_item.selling_plan_id.nil?
  end

  def all(line_item)
    true
  end
end

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
    else
      [line_item.line_price - (@discount_amount * line_item.quantity), Money.zero].max
    end

    line_item.change_line_price(new_line_price, message: @discount_message)
  end
end

class TieredProductDiscountByProductSpendCampaign
  def initialize(campaigns)
    @campaigns = campaigns
  end

  def run(cart)
    @campaigns.each do |campaign|
      if campaign[:product_selector_type] == :all
        total_applicable_cost = cart.subtotal_price
        applicable_items = cart.line_items
			elsif campaign[:product_selector_type] == :properties
					applicable_items = cart.line_items.select { |line_item| 
						line_item.properties and line_item.properties[campaign[:product_selectors_key]] == campaign[:product_selectors][0]
					}

					next if applicable_items.nil?

					total_applicable_cost = applicable_items.map(&:line_price).reduce(Money.zero, :+)
      else
        product_selector = ProductSelectorBA.new(
          campaign[:product_selector_match_type],
          campaign[:product_selector_type],
          campaign[:product_selectors],
        )

        applicable_items = cart.line_items.select { |line_item| product_selector.match?(line_item) }

        next if applicable_items.nil?

        total_applicable_cost = applicable_items.map(&:line_price).reduce(Money.zero, :+)
      end

      tiers = campaign[:tiers].sort_by { |tier| tier[:threshold] }.reverse
      applicable_tier = tiers.find { |tier|  total_applicable_cost >= (Money.new(cents: 100) * tier[:threshold]) }

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

CAMPAIGNS = [
  TieredProductDiscountByProductSpendCampaign.new(PRODUCT_DISCOUNT_TIERS),
  TieredProductDiscountByProductSpendCampaign.new(PRODUCT_DISCOUNT_TIERS_SUBSCRIPTION),
]

CAMPAIGNS.each do |campaign|
  campaign.run(Input.cart)
end

Output.cart = Input.cart

