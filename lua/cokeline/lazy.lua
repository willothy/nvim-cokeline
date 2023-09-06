return function(module)
  return setmetatable({}, {
    __index = function(_, k)
      return require(module)[k]
    end,
    __newindex = function(_, k, v)
      require(module)[k] = v
    end,
  })
end
