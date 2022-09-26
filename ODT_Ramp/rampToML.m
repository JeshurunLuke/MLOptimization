function func = rampToML(vend)
    % Linear ramp from old value to final value vend
  func = @(t, len, old_val) rampToHelper(t, len, old_val, vend);%(old_val .* (len - t) + vend .* t) ./ len;
end
