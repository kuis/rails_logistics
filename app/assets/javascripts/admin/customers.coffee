newCustomerPage = ->
  $properties = $('#corporate-properties')
  property_template = $('#property-template').html()
  property_index = 0

  add_property_fields = (index) ->
    html = Mustache.render(property_template, {index: index})
    $properties.prepend(html)

  add_property_fields(property_index)

  $('a.add-new-property').on 'click', ->
    property_index++
    add_property_fields(property_index)

  $('#create-customer').on 'click', () ->
    $form = $('#new-customer-form')
    $(@).attr('disabled', 'disabled')
    $form.find('#create-spinner').addClass('show')
    setTimeout (->
      $form.submit()
    ), 500
    return false

customersPage = ->
  newCustomerPage() if $('body').hasClass('admin-new-customer-page')

$(document).ready(customersPage)

