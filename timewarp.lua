script_name = "Timewarp"
script_description = "Stretches/offsets timestamps of selected subtitles"
script_author = "Joshua Walsh, chocmake"
script_version = "1.1"

form_elm_height = 1
row_height = 2
label_width = 8
field_width = 10
dialog = {}

function find_obj_by_val(array, key, value)
    for i = 1, #array do
        local obj = array[i]
        if obj[key] == value then
            return obj
        end
    end
    return nil
end

function ts_to_ms(timestamp)
    local h, m, s, frac = timestamp:match('^(%d%d?):(%d%d):(%d%d)%.?(%d?%d?%d?)$')
    local frac_new = 0

    h = tonumber(h)
    m = tonumber(m)
    s = tonumber(s)

    if not (h and m and s) then
        return nil
    end

    if frac and frac ~= "" then
        local shift = #frac
        frac = tonumber(frac)
        frac_new = frac / (10 ^ shift)
    end

    return (h * 3600 + m * 60 + s + frac_new) * 1000
end

function ms_to_ts(milliseconds)
    local ms = math.floor(milliseconds % 1000)
    local s_total = math.floor(milliseconds / 1000)
    local s = s_total % 60
    local m = (math.floor(s_total / 60)) % 60
    local h = math.floor(s_total / 3600)
    return string.format("%02d:%02d:%02d.%03d", h, m, s, ms)
end

function init_dialog(form, fields, sel, ts_fallback)
    dialog = {}
    for k,v in ipairs(form) do
        if not v.hide then
            i = k - 1 -- why can't Lua be zero indexed? :(
            dialog[i*2] = {
                class = "label",
                x = 0,
                y = row_height * i,
                width = label_width,
                height = form_elm_height,
                label = v.label
            }
            dialog[i*2 + 1] = {
                class = v.class,
                x = label_width,
                y = row_height * i,
                width = field_width,
                height = form_elm_height,
                name = v.name,
                text = v.name == fields[1] and sel.time.formatted.a or
                       v.name == fields[2] and sel.time.formatted.b or
                       ts_fallback
            }
        end
    end
end

function timewarp(subs, sel)
    local field_names = {"new_a", "new_b"}
    local fallback_time = "00:00:00.000"
    local form_elm = {
        {
            class = "edit",
            name = field_names[1],
            label = "New Time A"
        },
        {
            class = "edit",
            name = field_names[2],
            label = "New Time B"
        }
    } -- local to avoid deep copy for conditional label changes
    local field_a = form_elm[1]
    local field_b = form_elm[2]
    local sel_items = {
        index = {
            a = sel[1],
            b = sel[#sel]
        },
        time = {
            raw = {
                a = subs[sel[1]].start_time,
                b = subs[sel[#sel]].start_time
            },
            formatted = {
                a = ms_to_ts(subs[sel[1]].start_time) or fallback_time,
                b = ms_to_ts(subs[sel[#sel]].start_time) or fallback_time
            }
        }
    }
    local parsed = {
        orig_a = sel_items.time.raw.a,
        orig_b = sel_items.time.raw.b
    }
    local dur = {
        orig = parsed.orig_b - parsed.orig_a
    }

    local function shift_only()
        return dur.orig == 0
    end

    if shift_only() then
        field_b.hide = true
        field_a.label = "New Time Shift"
    else
        field_b.hide = false
    end

    init_dialog(form_elm, field_names, sel_items, fallback_time)
	proceed, inputs = aegisub.dialog.display(dialog)

	if proceed then
        local errors = ""

        for i,k in ipairs(field_names) do
            if field_b.hide and k == field_b.name then
                parsed[k] = parsed.orig_b
            else
                parsed[k] = ts_to_ms(inputs[k])
            end
            if not parsed[k] then
                errors = errors.. "Invalid timestamp input (".. find_obj_by_val(form_elm, "name", k).label.. "): " .. inputs[k].. "\n"
            end
        end

        if errors ~= "" then
            aegisub.log(1, errors.. "\n".. "Aborting.")
            aegisub.cancel()
            return
        end

        dur.new = parsed.new_b - parsed.new_a

        local function map_time(t)
            return (t - parsed.orig_a) / dur.orig * dur.new + parsed.new_a
        end

        if shift_only() then
            -- If distance between A and B is zero (eg: only one line selected, or two lines share same values) then do simple time shift
            local shift = parsed.new_a - parsed.orig_a
            for _,i in ipairs(sel) do
                local line = subs[i]
                line.start_time = line.start_time + shift
                line.end_time = line.end_time + shift
                subs[i] = line
            end
        else
            for pos,i in ipairs(sel) do
                local line = subs[i]

                -- Interpolate start time for all selections
                line.start_time = map_time(line.start_time)

                -- Check if endmost item (B)
                if pos == #sel then
                    -- Only change B's end time if B's start time has been modified (avoids original issue where B's end time can have calc incorrectly applied when only A's value has been changed)
                    if parsed.new_b ~= parsed.orig_b then
                        local orig_end_offset = line.end_time - parsed.orig_b
                        line.end_time = parsed.new_b + orig_end_offset
                    end
                else
                    -- For A/in-between lines interpolate as usual
                    line.end_time = map_time(line.end_time)
                end

                subs[i] = line
            end
        end

		aegisub.set_undo_point(script_name)
	end
end

function check_minsel_1(subs, sel)
	return #sel >= 1
end

aegisub.register_macro(script_name, script_description, timewarp, check_minsel_1)
