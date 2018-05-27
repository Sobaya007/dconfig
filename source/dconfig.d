import std.json;

class ConfigManager {

    /* Singleton Implementation */
    private static ConfigManager instance;

    public static ConfigManager opCall() {
        if (instance is null) instance = new ConfigManager;
        return instance;
    }

    /* Signal Declaration */
    import std.signals;
    mixin Signal;
    mixin Signal!(string, string, JSONValue);


    /* Field Declaration */
    private ConfigFile[] files;


    // load all config files and update config variables
    void load() {
        emit();
    }

    // return ConfigFile instance using cache if available
    ConfigFile getFile(string path) {
        import std.algorithm : find;
        import std.array : empty, front;

        auto findResult = this.files.find!(file => file.path == path);
        if (!findResult.empty) return findResult.front;

        auto newFile = new ConfigFile(path);
        this.files ~= newFile;

        return newFile;
    }

    // notify config variable update
    private void setValue(string path, string name, JSONValue val) {
        emit(path, name, val);
    }
}


private class ConfigFile {

    /* Signal Declaration */
    import std.signals;
    mixin Signal!(string, string, JSONValue);

    /* Field Declaration */
    private string path;


    private this(string path) {
        this.path = path;

        // connect instances
        // ConfigManager.emit -> ConfigFile.load -> ConfigManager.load -> ConfigVariable.setValue
        this.connect(&ConfigManager().setValue);
        ConfigManager().connect(&this.load);
    }


    void load() {
        import std.file : readText;

        auto jsonData = parseJSON(readText(path));
        foreach (string key, value; jsonData) {
            emit(path, key, value);
        }
    }
}


// converts JSONValue to normal type. (name is necessary only for assertion)
static auto conv(T)(string name, JSONValue value) {

    import std.traits : isAssignable, isArray, isStaticArray, ForeachType;

    switch (value.type) {
        case JSON_TYPE.STRING:
            static if (isAssignable!(T, string)) {
                return value.str();
            } else {
                break;
            }
        case JSON_TYPE.ARRAY:
            static if (isArray!(T) && !isAssignable!(T, string)) {
                import std.algorithm : map;
                import std.array;
                static if (isStaticArray!(T)) {
                    import std.format;
                    auto jsonArray = value.array();
                    assert(T.length == jsonArray.length, format!"Expected length is '%d', but %s's length is '%d'."(T.length, name, jsonArray.length));
                    T ar;
                    foreach (i, v; jsonArray) {
                        ar[i] = conv!(ForeachType!(T))(name, v);
                    }
                    return ar;
                } else {
                    return value.array().map!(v => conv!(ForeachType!(T))(name, v)).array;
                }
            } else {
                break;
            }
        case JSON_TYPE.FLOAT:
            static if (isAssignable!(T, double) && !isArray!(T)) {
                return cast(float)value.floating();
            } else {
                break;
            }
        case JSON_TYPE.INTEGER:
            static if (isAssignable!(T, int) && !isArray!(T)) {
                return cast(int)value.integer();
            } else {
                break;
            }
        case JSON_TYPE.UINTEGER:
            static if (isAssignable!(T, uint) && !isArray!(T)) {
                return cast(uint)value.uinteger();
            } else {
                break;
            }
        case JSON_TYPE.TRUE:
            static if (isAssignable!(T, bool) && !isArray!(T)) {
                return true;
            } else {
                break;
            }
        case JSON_TYPE.FALSE:
            static if (isAssignable!(T, bool) && !isArray!(T)) {
                return false;
            } else {
                break;
            }
        default:
            import std.format;
            assert(false, format!"Type '%s' is not allowed."(value.type));
    }
    import std.format;
    assert(false, format!"Expected Type is '%s', but %s's type is '%s'."(T.stringof, name, value.type));
}


// UDA for config variable
static struct config {
    string filePath;
}


mixin template HandleConfig() {

    // for a class mixin this, this import is needed.
    import std.json;

    // activate config variables.
    // after calling this, config variables are assigned and accept reloading.
    private void initializeConfig() {
        import std.algorithm : sort, uniq;
        import std.traits : getSymbolsByUDA, getUDAs;
        import std.meta : AliasSeq;

        alias symbols = AliasSeq!(getSymbolsByUDA!(typeof(this), config));
        
        string[] files;
        static foreach (i; 0..symbols.length) {{
            import std.string : replace;

            enum SymbolName = symbols[i].stringof.replace("this.", "");
            alias SymbolType = typeof(symbols[i]);
            enum FilePath = getUDAs!(symbols[i], config)[0].filePath;

            // connect ConfigManager.setValue -> ConfigVariable.setValue
            ConfigManager().connect(&this.setValue!(FilePath, SymbolName, SymbolType));

            files ~= FilePath;
        }}

        // first loading
        foreach (filePath; files.sort().uniq()) {
            ConfigManager().getFile(filePath).load();
        }
    }

    private void setValue(string FilePath, string SymbolName, SymbolType)(string path, string name, JSONValue value) {
        if (FilePath != path) return;
        if (SymbolName != name) return;

        mixin("this." ~ SymbolName) = conv!(SymbolType)(name, value);
    }

}
