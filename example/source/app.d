import std.stdio;
import dconfig;

// To use this library, you must prepare class.
class ConfigClass {

    // class for dconfig must mixin 'HandleConfig'.
    mixin HandleConfig;

    this() {
        // after calling 'initializeConfig', you can use config variables.
        this.initializeConfig();
    }


    // by adding UDA '@config(JSON_PATH)', these variables are recognized as config variables.
    @config("test.json") {

        // basic types are available
        int intVariable;
        uint uintVariable;
        float floatVariable;
        bool boolVariable;
        string stringVariable;

        // array whose element is basic is also available.
        int[3] intStaticArray;
        int[] intDynamicArray;
        int[3][2] multiArray;

        // struct that can be assigned basic type is also available.
        IntAcceptable structVariable;

        // enum type is available. They are saved as string.
        Color enumVariable;
    }
    struct IntAcceptable {int x; alias x this; }
    enum Color {Red, Green, Blue}
}

void main() {
    import std.file : copy, remove;

    // prepare json file
    copy("test1.json", "test.json");

    with(new ConfigClass()) {
        import std.math : approxEqual;

        // now, each variables are already assigned.
        assert(intVariable == 114514);
        assert(uintVariable == 114514);
        assert(approxEqual(floatVariable, 8.10, float.epsilon));
        assert(boolVariable == true);
        assert(stringVariable == "testString");
        assert(intStaticArray == [3, 3, 4]);
        assert(intDynamicArray == [3, 3, 4]);
        assert(multiArray == [[1,2,3], [4,5,6]]);
        assert(structVariable == 334);
        assert(enumVariable == Color.Blue);

        // if source json file is rewritten while running, you can reload.
        copy("test2.json", "test.json");
        ConfigManager().load();

        assert(intVariable == -114514);
        assert(uintVariable == 0);
        assert(approxEqual(floatVariable, -8.10, float.epsilon));
        assert(boolVariable == false);
        assert(stringVariable == "testString2");
        assert(intStaticArray == [-3, 3, 4]);
        assert(intDynamicArray == [-3, 3, 4]);
        assert(multiArray == [[4,5,6], [1,2,3]]);
        assert(structVariable == -334);
        assert(enumVariable == Color.Green);
    }

    // delete temporary json file
    remove("test.json");

    with(new ConfigClass()) {
        // if file does not exist, variables are assigned default value.
        import std.math : isNaN;
        assert(intVariable == 0);
        assert(uintVariable == 0);
        assert(floatVariable.isNaN);
        assert(boolVariable == false);
        assert(stringVariable == "");
        assert(intStaticArray == [0,0,0]);
        assert(intDynamicArray == []);
        assert(multiArray == [[0,0,0], [0,0,0]]);
        assert(structVariable == 0);
        assert(enumVariable == Color.Red);

        // variables can be assigned.
        intVariable = 1;
        uintVariable = 1;
        floatVariable = 4;
        boolVariable = true;
        stringVariable = "514";
        intStaticArray = [8,1,0];
        intDynamicArray = [9,3,1];
        multiArray = [[1,1,4], [5,1,4]];
        structVariable = 1_000_000_007;
        enumVariable = Color.Green;

        // save current variable state.
        saveConfig();
    }

    with(new ConfigClass()) {
        // saved variables are retained.
        import std.math : isNaN, approxEqual;
        assert(intVariable == 1);
        assert(uintVariable == 1);
        assert(approxEqual(floatVariable, 4, float.epsilon));
        assert(boolVariable == true);
        assert(stringVariable == "514");
        assert(intStaticArray == [8,1,0]);
        assert(intDynamicArray == [9,3,1]);
        assert(multiArray == [[1,1,4], [5,1,4]]);
        assert(structVariable == 1_000_000_007);
        assert(enumVariable == Color.Green);
    }

    // delete temporary json file
    remove("test.json");
}
