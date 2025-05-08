-- ZonaMerah Reflection Utilities

ZM_ReflectionUtils = {}

function ZM_ReflectionUtils.inspectObject(object, options)
    options = options or {}
    local results = {
        fields = {},
        methods = {}
    }

    -- Get all fields
    for i = 0, getNumClassFields(object) - 1 do
        local field = getClassField(object, i)
        local fieldName = tostring(field)
        local shortName = fieldName:match("[^%.]+$") or fieldName
        local value

        -- Try to get field value
        local success, result = pcall(function()
            return getClassFieldVal(object, field)
        end)

        if success then
            value = result
        else
            -- If direct access failed, try methods
            value = ZM_ReflectionUtils.tryMethodVariants(object, shortName)
        end

        -- Format boolean values
        if type(value) == "boolean" then
            value = value and "true" or "false"
        end

        results.fields[fieldName] = value
    end

    -- Discover methods if requested
    if options.discoverMethods then
        ZM_ReflectionUtils.discoverMethods(object, results.methods)
    end

    return results
end

function ZM_ReflectionUtils.tryMethodVariants(object, fieldName)
    if not fieldName then return "ERROR ACCESSING FIELD" end

    -- Generate method variants
    local methodVariants = {
        fieldName, -- Try as-is
        "is" .. fieldName:gsub("^is", ""), -- Try with "is" prefix
        "get" .. fieldName:gsub("^get", ""), -- Try with "get" prefix
        "has" .. fieldName:gsub("^has", ""), -- Try with "has" prefix
        fieldName .. "ed", -- For past tense properties (scratched, bandaged)
        fieldName:gsub("ed$", "") -- For method versions of past tense properties
    }

    -- Try each variant
    for _, variant in ipairs(methodVariants) do
        if type(object[variant]) == "function" then
            local success, result = pcall(function()
                return object[variant](object)
            end)
            if success then
                return result
            end
        end
    end

    return "ERROR ACCESSING FIELD"
end

function ZM_ReflectionUtils.discoverMethods(object, methodsTable)
    -- Try standard method discovery using PZ debug method if available
    if getTableValues and type(getTableValues) == "function" then
        pcall(function()
            local methodNames = getTableValues(object)
            for _, methodName in ipairs(methodNames) do
                if type(object[methodName]) == "function" then
                    methodsTable[methodName] = "METHOD"
                end
            end
        end)
    end
end

function ZM_ReflectionUtils.writeInspectionToFile(results, filePath, header)
    if not results then
        print("Error: results is nil")
        return false
    end

    local fileWriter = getFileWriter(filePath, true, false)
    if not fileWriter then
        print("Error: couldn't create file writer for " .. tostring(filePath))
        return false
    end

    -- Write header if provided
    if header then
        fileWriter:write(header .. "\n\n")
    end

    -- Write fields
    fileWriter:write("=== Fields ===\n")
    if type(results.fields) == "table" then
        local fieldCount = 0
        for fieldName, value in pairs(results.fields) do
            if fieldName then  -- Make sure fieldName isn't nil
                fileWriter:write(tostring(fieldName) .. " = " .. tostring(value) .. "\n")
                fieldCount = fieldCount + 1
            end
        end

        if fieldCount == 0 then
            fileWriter:write("No fields found\n")
        end
    else
        fileWriter:write("No fields found or fields data is not a table\n")
    end
    fileWriter:write("\n")

    -- Write methods if any were discovered
    if type(results.methods) == "table" then
        -- First check if methods table has any entries
        local hasEntries = false
        for _ in pairs(results.methods) do
            hasEntries = true
            break
        end

        if hasEntries then
            fileWriter:write("=== Methods ===\n")
            for methodName, info in pairs(results.methods) do
                if methodName then  -- Make sure methodName isn't nil
                    fileWriter:write(tostring(methodName) .. "\n")
                end
            end
        end
    end

    fileWriter:close()
    return true
end

return ZM_ReflectionUtils