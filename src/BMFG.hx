package;

class BMFG {

    public static function main() {
        
        var app = new App();
        if (!app.init()) {
            trace("Failed to initialize application");
            return;
        }

        app.addState(new FontBakerState(app));
        app.run();
    }
    
    static function printHelp():Void {
        // Parse command-line arguments
        var args = new Args();
        
        // Example: Handle help flag
        if (args.has("--help") || args.has("-h")) {
            printHelp();
            return;
        }
        
        // Example: Debug mode flag
        if (args.has("--debug") || args.has("-d")) {
            trace("Debug mode enabled");
        }

        trace("BMFG - Bitmap Font Generator");
        trace("");
        trace("Usage: BMFG-debug.exe [options]");
        trace("");
        trace("Options:");
        trace("  --help, -h           Show this help message");
        trace("  --debug, -d          Enable debug mode");
        trace("  --width <value>      Set window width");
        trace("  --height <value>     Set window height");
        trace("");
    }
}