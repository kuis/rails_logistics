$(document).ready ->
  profile_form = $("form.user-profile")
  form_attributes = profile_form.serialize()
  
  profile_form.submit ->
    val = $("input[type=submit][clicked=true]").val()
    $("<input type='hidden' value='#{val}' name='submit_button'>").appendTo(@)

  profile_form.find("input[type=submit]").click ->
    $("input[type=submit]", $(this).parents("form")).removeAttr "clicked"
    $(this).attr "clicked", "true"
    return

  profile_form.find(".select-avatar").on 'click', ->
    profile_form.find("#avatar-file-field").trigger('click')
    profile_form.find("#user_remove_avatar").attr "checked", false

  profile_form.find("#avatar-file-field").on 'change', (e) ->
    evt = e.target
    if evt.files and evt.files[0]
      reader = new FileReader()
      reader.onload = (e) ->
        profile_form.find("#avatar-img").attr "src", e.target.result
        return
      reader.readAsDataURL evt.files[0]
    submits = profile_form.find('input.enabled-on-changes, button.enabled-on-changes')
    submits.prop('disabled', false)

  profile_form.find(".remove-avatar").on 'click', ->
    profile_form.find("#user_remove_avatar").attr "checked", true
    profile_form.find("#avatar-img").attr "src", "/assets/adminre_theme_v120/image/avatar/avatar.png"
    profile_form.find("#avatar-file-field").trigger('change')
