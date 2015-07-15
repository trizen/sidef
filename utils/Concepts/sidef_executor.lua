#!/usr/bin/lua

-- Sidef executor in Lua

String = setmetatable({
    __index = function(self, i)
        return String[i]
    end,

    concat = function(self, arg)
        return String(self.value .. arg.value)
    end,

    say = function(self)
        self:concat(String("\n")):print();
    end,

    print = function(self)
        io.write(self.value);
    end,
},
{
    __call = function(self, val)
        return setmetatable({value = val}, String)
    end
});

function execute_expr(statement)

    local self_obj = statement['self'];

    if (type(self_obj) == "table" and getmetatable(self_obj) == nil) then
        self_obj = execute(self_obj);
    end

    if (statement['call'] ~= nil) then
        for i = 1, #(statement['call']) do

            local call = statement['call'][i];
            local meth = call['method'];

            if (call['arg'] ~= nil) then

                local args = {};
                local call_args = call['arg'];

                for i = 1, #call_args do
                    local arg = call_args[i];

                    if (type(arg) == "table" and getmetatable(arg) == nil) then
                        arg = execute_expr(arg);
                    end

                    args[i] = arg;
                end

                self_obj = self_obj[meth](self_obj, unpack(args));
            else
                self_obj = self_obj[meth](self_obj);
            end

        end
    end

    return self_obj;
end

function execute(structure)
    local results = {};

    for i = 1, #(structure['main']) do
        local statement = structure['main'][i];
        results[i] = execute_expr(statement);
    end

    return results[#results];
end

local ast = {
    main = {
        {
            call = {{method = "print"}},
            self = {
                main = {
                    {
                        call = {{method = "concat", arg = {{self = String("llo")}}}},
                        self = String("he"),
                    }
                },
            }
        },
        {
            call = {{method = "say"}},
            self = String(" world!");
        },
    }
}

execute(ast);
