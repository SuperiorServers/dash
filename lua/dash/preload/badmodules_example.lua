-- This folder has total load priority over everything
-- This can be used to kill modules you dont use on your server
-- require 'example'  will now silently ignore this module
dash.BadModules['example'] = true