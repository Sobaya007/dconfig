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
    }
    struct IntAcceptable {int x; alias x this; }
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

        // you can modify the values.
        intVariable = -810;
        uintVariable = 1919;
        floatVariable = 3.34;
        boolVariable = true;
        stringVariable = "testString3";
        intStaticArray = [25, 25, 21];
        intDynamicArray = [2, 5, 2, 5, 2, 1];
        multiArray= [[3,3,4], [9,3,1]];
        structVariable = 1;

        // and you can save the values.
        saveConfig();
    }

    // you want to restart?
    with(new ConfigClass()) {
        import std.math : approxEqual;

        // ok, you can load the saved values
        assert(intVariable == -810);
        assert(uintVariable == 1919);
        assert(approxEqual(floatVariable, 3.34, float.epsilon));
        assert(boolVariable == true);
        assert(stringVariable == "testString3");
        assert(intStaticArray == [25, 25, 21]);
        assert(intDynamicArray == [2, 5, 2, 5, 2, 1]);
        assert(multiArray== [[3,3,4], [9,3,1]]);
        assert(structVariable == 1);
    }

    // delete temporary json file
    remove("test.json");
}
