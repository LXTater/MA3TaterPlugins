function TaterFXForm()                              --Function to open the form select popup
  local key, value = PopupInput({
    title = 'Form',
    caller = GetFocusDisplay(),
    items = {'Sin', 'Chase', 'RampPlus','RampMinus'}
  })

  if value then                                         -- If statement to gather value from swipedown, and change user Variable to user selection
    Cmd('SetUserVar TaterFXForm ' .. value)
    Cmd('Copy Appearance form_'.. value .. ' At TaterFXForm "TaterFXForm" /NoOops /Overwrite')
    Printf('TaterFX: Form set to ' .. value)
    
    
  else
    Printf('TaterFX: User cancelled, or an error occurred.')           --Detects cancellation or error...
  end
end

return TaterFXForm

