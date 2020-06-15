# Monetization

With In-Skill Purchasing (ISP), you can sell premium content via "products" in your Alexa skills.
This offers a great way of monetizing your Alexa skills.

::: warning NOTE

As of April 2019, only skills published in the US Alexa Skill Store can offer in-skill purchases.
That said, in-skill purchase capabilities will soon be rolled out to additional countries.

:::

## Product Models

There are three different types of products that you can offer in your skills.

### 1. Entitlements (one-time purchase)

Entitlements (priced at $0.99 - $99.99) can persistently unlock in-skill features/content.

:::tip Use case examples:

* premium question packs in a trivia game
* additional content for a choose-your-own-adventure story skill

:::

### 2. Subscriptions (recurring purchase)

Subscriptions (priced at $0.99 - $99.99) can unlock in-skill features/content for a limited
period of time. The subscription period can be monthly or yearly, and users will be charged the
subscription price on a recurring basis until they cancel their subscription. It is also possible to
offer a free trial period for your subscription (recommended) of up to 31 days.

:::tip Use case examples:

* access to a radio broadcast skill
* podcast skill with regularly updated episodes

:::

### 3. Consumables

Consumables (priced at $0.99 - $9.99) can unlock in-skill items that are depleted upon usage.

:::tip Use case examples:

* extra lives in a survival adventure skill
* hints in a puzzle skill
* in-skill currency for a farming skill

:::

## ISP in Litexa

Litexa facilitates adding In-Skill Purchasing logic to your skills. Below, we'll take you through
the process of using in-skill products in 10 steps from creating the product(s), to managing your
earnings in the released skill.

### Step 1: Create in-skill product(s)

First, you'll need to create any required in-skill products. To do so, make sure you've `litexa
deploy`ed your skill at least once, and then proceed as follows:

1. Head to your [ASK Developer Console](https://developer.amazon.com/alexa/console/ask).
2. Select your skill from 'Alexa Skills'.
3. Select 'IN-SKILL PRODUCTS'.
4. Select 'Create in-skill product'.
5. Follow the instructions, and fill out all required fields (marked with *). Feel free to use
placeholders (but remember to replace them by editing the product, later).
6. Upon completing the in-skill product, you will be prompted to link it to your skill: Confirm with
'Link to skill'.

Repeat the above steps 4-6 for any products you'd like to create for your skill.

### Step 2: Pull in-skill product(s)

You should pull the JSON definitions of your skill's in-skill products, so that any product
references can be properly tested by Litexa. To do so, simply run the following command from your
Litexa project's root directory.

```bash
litexa pull isp
```

This will create an `isp` directory in your project root directory, with a subdirectory for the
deployment stage you specify (default: `development`). A JSON file will then be created within, for
every in-skill product associated with the specified stage of your skill.

For example, assuming you've linked a product with the reference name "MyPremiumProduct" to your
skill in the `development` stage, you would see the following file structure:

```
project_dir
└── isp
    └── development
        └── MyPremiumProduct.json
└── litexa
```

:::warning isp pulling overrides local products
Any local product files will be replaced by remote products during `pull isp`.
:::

If you prefer modifying your in-skill products locally via their JSON, you can do so and push
these changes with the following command:

```bash
litexa push isp
```

:::warning isp pushing overrides remote products
Any remote products will be replaced by local products during `push isp`.
:::

### Step 3: Configure your skill for ISP

In your skill configuration file (`skill.*`), set allowsPurchases to true:

```js
 privacyAndCompliance: {
  allowsPurchases: true
  // ...
 }
 ```

### Step 4: Support purchasing

You must handle a buy intent, whether or not the user specifies a product name.

1. Example of handling a request for general product information:

```coffeescript
when "what can I buy"
  or "what can I shop for"
  or "tell me what I can buy"
  or "buy"
  or "shop"
  say "You can purchase the following product: MyPremiumProduct. If you're interested,
    say: Alexa, buy MyPremiumProduct."
```

:::tip Don't overwhelm the user with products
If you have multiple products, you should split up your product information. For instance:

```coffeescript
when "what can I buy"
  say "You can buy A, B, or C. Or say, next, to hear more options."
when AMAZON.NextIntent
  say "You can also buy D, E, or F."
```

Also, don't mention products already owned by the user, by using `inSkillProductBought`.
:::

2. Example of handling a request for a specific product:

```coffeescript
when "buy MyPremiumProduct"
  or "purchase MyPremiumProduct"
  or "give me MyPremiumProduct"

  if inSkillProductBought(context, "MyPremiumProduct")
    say "It looks like you've already bought MyPremiumProduct!"
  else
    buyInSkillProduct "MyPremiumProduct"
```

:::tip buyInSkillProduct
The above `buyInSkillProduct` statement automatically generates a purchase directive for the product
indicated by its reference name. Doing so will initiate a purchase flow outside of your skill
(temporarily exiting it), during which the purchasePromptDescription and price for the indicated
product are shared with the user, allowing them to purchase the product.

If necessary, you should take note of your user's progress in the skill before initiating a
purchase, so you can gracefully resume the skill upon relaunch. For example, if you want to
directly pick up from the state the user was in, you could save that state's name to a database
variable and then add the necessary redirection logic to your `launch` state.
:::

An alternative to using `buyInSkillProduct` is the `upsellInSkillProduct` statement. The main
difference between the two is that `upsellInSkillProduct` will first prompt the user with a
specified upsell message, which should be formulated as a Yes/No question, as seen below:

```coffeescript
upsellInSkillProduct "MyPremiumProduct"
  message: "A premium product is available. Would you like to learn more?"
```

If the user answers "Yes", the flow would proceed to present the same product prompt/price as
`buyInSkillProduct`. If the user answers "No", the upsell flow would silently abort and relaunch
the skill.

### Step 5: Support refund/cancellation

Similarly to supporting purchase intents, you must also support cancellation/refund requests. For
example:

```coffeescript
# handle the user specifying no product name
when "cancel purchase"
  or "stop purchase"
  or "refund purchase"
  # Ideally remind user of what they've purchased.
  say "Please specify which product you'd like to cancel."

when "refund MyPremiumProduct"
  or "I want to return MyPremiumProduct"
  or "I want a refund for MyPremiumProduct"

  if inSkillProductBought(context, "MyPremiumProduct")
    cancelInSkillProduct "MyPremiumProduct"
  else
    say "It doesn't look like you currently own MyPremiumProduct."
```

:::tip cancelInSkillProduct
Similarly to the above `buyInSkillProduct` statement, the `cancelInSkillProduct` statement will
automatically initiate a cancellation directive for the indicated product, which will proceed to
launch a purchase cancellation flow outside of your skill.

Again, you should first store your user's progress (if necessary), so you can gracefully resume your
skill when it's automatically relaunched.
:::

### Step 6: Handle purchase result

As stated above, buying/canceling an in-skill product will temporarily exit your skill. Once
automatically relaunched, your skill will receive a `Connections.Response` event with the
"purchaseResult". To see the structure of the response and more information on its fields, refer to
[Resuming your skill after the purchase flow](https://developer.amazon.com/docs/in-skill-purchase/add-isps-to-a-skill.html#handle-results)

The purchaseResult can be one of four values:

1. ACCEPTED
2. DECLINED
3. ALREADY_PURCHASED
4. ERROR

To listen for and handle the purchaseResult, use the following code in a `global` state intent
handler:

```coffeescript
global
  when Connections.Response "Buy"    # handles return from buyInSkillProduct
    switch $purchaseResult
      == "ACCEPTED" then
        say "You now own {$newProduct.name}!"
      == "DECLINED" then
        # ...
      == "ALREADY_PURCHASED"  then
        # ...
      == "ERROR" then
        # ...

  when Connections.Response "Upsell" # handles return from upsellInSkillProduct
    switch $purchaseResult
      == "ACCEPTED" then
        # ...

  when Connections.Response "Cancel" # handles return from cancelInSkillProduct
    switch $purchaseResult
      == "ACCEPTED" then
        # ...
```

:::tip $purchaseResult, $newProduct
As seen in the above example, using a `when Connections.Response "Buy"|"Cancel"|"Upsell"` listener
will automatically create two shorthand [$ variables](/reference/#variable-2) with the purchase
result and the relevant product! These can then be handled in whichever way is required.
`$newProduct` will have the following structure:

```json
{

  "productId": "amzn1.adg.product.myProductsProductId",
  "referenceName": "myProductsReferenceName",
  "type": "ENTITLEMENT",
  "name": "My Product Name",
  "summary": "My product's summary.",
  "entitled": "NOT_ENTITLED",
  "entitlementReason": "NOT_PURCHASED",
  "purchasable": "PURCHASABLE",
  "activeEntitlementCount": 0,
  "purchaseMode": "TEST"
}
```

Further details on this product summary can be found in the
[ASK InSkillProduct documentation](https://developer.amazon.com/docs/in-skill-purchase/in-skill-product-service.html#inskillproduct).

:::

### Step 7: Handle bought products

Now, all that remains for you to add in your skill is logic to account for products owned by the
user. This is done with the `inSkillProductBought` function:

```coffeescript
startGame
  if inSkillProductBought(context, "MyPremiumProduct")
    say "Would you like to play the standard or premium edition?"
    # ...
  else
    say "Would you like to play the free standard edition, or
      are you interested in purchasing the premium edition?"
    # ...
```

### Step 8: Testing ISP

It is possible to test purchasing during skill development, without accruing any purchase charges.
For instructions on how to do so, and on how to reset existing entitlements through the ASK
Developer Console, please refer to the
[ISP Test Guide](https://developer.amazon.com/docs/in-skill-purchase/isp-test-guide.html).

:::tip Litexa reset shortcut
Resetting all test purchases for a skill in development can also be achieved with the following
CLI command:

```bash
litexa reset isp
```

:::

### Step 9: Certifying your ISP skill

To get your skill with ISP certified, a couple additional steps are required:

* [ISP Tax Setup](https://developer.amazon.com/docs/in-skill-purchase/setup-tax.html)
* [ISP Certification Guide](https://developer.amazon.com/docs/in-skill-purchase/isp-certification-guide.html)

### Step 10: ISP Earnings/Metrics

Once your skill is live, purchase metrics can be found and viewed here:

* [ISP Metrics](https://developer.amazon.com/docs/devconsole/measure-skill-usage.html#isp-metrics)
* [View Earnings and Payments](https://developer.amazon.com/docs/devconsole/view-payments-earnings.html)

## ISP Best Practices

In-skill products should enhance the experience of your skill, but should not be required. Every
skill should provide a free experience that is self-sufficient and can engage customers. The free
experience should drive interest in any premium content, without foisting it on users who aren't
interested in purchasing said content.

For detailed practices, we encourage you to review this documentation of how to
[Design a Good Customer Experience for In-Skill Purchasing](
  https://developer.amazon.com/docs/in-skill-purchase/customer-experience.html)

## Relevant Resources

* [In-Skill Purchasing Overview](https://developer.amazon.com/docs/in-skill-purchase/isp-overview.html)
* [Create and Manage In-Skill Products](https://developer.amazon.com/docs/in-skill-purchase/create-isp-dev-console.html)
* [Design a Good Customer Experience for ISP](https://developer.amazon.com/docs/in-skill-purchase/customer-experience.html)
* [ISP Testing Guide](https://developer.amazon.com/docs/in-skill-purchase/isp-test-guide.html)
* [ISP Certification Guide](https://developer.amazon.com/docs/in-skill-purchase/isp-certification-guide.html)
* [Set Up Tax Forms for Your Account](https://developer.amazon.com/docs/in-skill-purchase/setup-tax.html)
* [Understand and Set Up Payments](https://developer.amazon.com/docs/in-skill-purchase/isp-payments.html)
* [ISP FAQ](https://developer.amazon.com/docs/in-skill-purchase/isp-faqs.html)
