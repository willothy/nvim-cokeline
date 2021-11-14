local M = {}

M.Slider = {}

function M.Slider:new()
  local slider = {
    widths = {
      left = 0,
      right = 0,
    },
  }
  setmetatable(slider, self)
  self.__index = self
  return slider
end

M.StatelessSlider = M.Slider:new()
M.StatefulSlider = M.Slider:new()

M.CenterFocusedSlider = M.StatelessSlider:new()

function M.CenterFocusedSlider:compute_spaces(available_left_right)
  -- This slider computes the spaces left and right of the focused line so as
  -- to always keep it as centered as possible.
  local available = {
    left = math.floor(available_left_right/2),
    right = math.floor(available_left_right/2) + available_left_right % 2,
  }

  local unused = {
    left = math.max(available.left - self.widths.left, 0),
    right = math.max(available.right - self.widths.right, 0),
  }

  return {
    left = available.left - unused.left + unused.right,
    right = available.right - unused.right + unused.left,
  }
end

M.GradualSlider = M.StatefulSlider:new()

M.GradualSlider.scrolloff = {
  left = 5,
  right = 5,
}

function M.GradualSlider:compute_spaces(space_left_right)
  return {
    left = self.scrolloff.left,
    right = self.scrolloff.right,
  }
end

return M
