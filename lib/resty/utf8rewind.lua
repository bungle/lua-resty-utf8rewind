local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local ffi_typeof = ffi.typeof
local ffi_sizeof = ffi.sizeof
local tonumber = tonumber
local assert = assert
local upper = string.upper
local type = type
ffi_cdef [[
typedef uint16_t utf16_t;
typedef uint32_t unicode_t;
typedef int64_t off_t;
 size_t utf8len(const char* text);
 size_t utf8toupper(const char* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf8tolower(const char* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf8totitle(const char* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf8casefold(const char* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf16toutf8(const utf16_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf32toutf8(const unicode_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t widetoutf8(const wchar_t* input, size_t inputSize, char* target, size_t targetSize, int32_t* errors);
 size_t utf8toutf16(const char* input, size_t inputSize, utf16_t* target, size_t targetSize, int32_t* errors);
 size_t utf8toutf32(const char* input, size_t inputSize, unicode_t* target, size_t targetSize, int32_t* errors);
 size_t utf8towide(const char* input, size_t inputSize, wchar_t* target, size_t targetSize, int32_t* errors);
uint8_t utf8isnormalized(const char* input, size_t inputSize, size_t flags, size_t* offset);
 size_t utf8normalize(const char* input, size_t inputSize, char* target, size_t targetSize, size_t flags, int32_t* errors);
const char* utf8seek(const char* text, size_t textSize, const char* textStart, off_t offset, int direction);
]]
local lib    = ffi_load     "utf8rewind"
local errors = ffi_new      "int32_t[1]"
local offset = ffi_new       "size_t[1]"
local char_t = ffi_typeof      "char[?]"
local utf16t = ffi_typeof   "utf16_t[?]"
local unicod = ffi_typeof "unicode_t[?]"
local wchart = ffi_typeof   "wchar_t[?]"
local FLAGS = {
       C = 1,
     NFC = 1,
       D = 2,
     NFD = 2,
      KC = 5,
    NFKC = 5,
      KD = 6,
    NFKD = 6
}
local utf8rewind = { maybe = {} }
local function process(input, func, target_t, flags)
    local t = target_t or char_t
    local l = type(input) == "cdata" and ffi_sizeof(input) or #input
    local s = flags and lib[func](input, l, nil, 0, flags, errors) or lib[func](input, l, nil, 0, errors)
    if errors[0] == 0 then
        local target = ffi_new(t, s)
        s = flags and lib[func](input, l, target, s, flags, errors) or lib[func](input, l, target, s, errors)
        if errors[0] == 0 then
            if target_t then
                return target, tonumber(s)
            else
                return ffi_str(target, s), tonumber(s)
            end

        end
    end
    return nil, errors[0]
end
function utf8rewind.utf8len     (input) return tonumber(lib.utf8len(input))   end
function utf8rewind.utf8toupper (input) return process(input, "utf8toupper")  end
function utf8rewind.utf8tolower (input) return process(input, "utf8tolower")  end
function utf8rewind.utf8totitle (input) return process(input, "utf8totitle")  end
function utf8rewind.utf8casefold(input) return process(input, "utf8casefold") end
function utf8rewind.utf16toutf8 (input) return process(input, "utf16toutf8")  end
function utf8rewind.utf32toutf8 (input) return process(input, "utf32toutf8")  end
function utf8rewind.widetoutf8  (input) return process(input, "widetoutf8")   end
function utf8rewind.utf8toutf16 (input) return process(input, "utf8toutf16", utf16t) end
function utf8rewind.utf8toutf32 (input) return process(input, "utf8toutf32", unicod) end
function utf8rewind.utf8towide  (input) return process(input, "utf8towide",  wchart) end
function utf8rewind.utf8normalize(input, flags)
    flags = flags or FLAGS.C
    if type(flags) == "string" then
        flags = FLAGS[flags]
    end
    assert(type(flags) == "number", "Invalid normalization flags supplied.")
    return process(input, "utf8normalize", nil, flags)
end
function utf8rewind.utf8isnormalized(input, flags)
    flags = flags or FLAGS.C
    if type(flags) == "string" then
        flags = FLAGS[upper(flags)]
    end
    assert(type(flags) == "number", "Invalid normalization flags supplied.")
    local r = lib.utf8isnormalized(input, #input, flags, offset)
    local n = tonumber(offset[0])
    if r == 0 then
        return true, true, n
    elseif r == 2 then
        return false, false, n
    else
        return false, true, n
    end
end
function utf8rewind.utf8seek(input, offset, direction)
    return ffi_str(lib.utf8seek(input, #input, input, offset or 0, direction and 2 or 0))
end
return utf8rewind