package;

import State;
import App;
import Renderer;
import utils.FontBaker;
import display.BitmapFont;
import display.Text;
import entity.DisplayEntity;
import loaders.FontLoader;

/**
 * FontBakerState - Test state for baking TrueType fonts to bitmap atlases
 * 
 * This state demonstrates using stb_truetype to generate font atlases
 * from .ttf files. The baked fonts can then be used with the existing
 * BitmapFont/Text rendering system.
 */
class FontBakerState extends State {
    
    private var bitmapFont:BitmapFont;
    private var displayText:Text;
    private var currentFontSize:Float = 20.0;
    private var fontPath:String;
    private var outputName:String;
    
    public function new(app:App) {
        super("FontBakerState", app);
    }
    
    override public function init():Void {
        super.init();
        
        // Set up orthographic camera for 2D text rendering
        camera.ortho = true;
        
        // Log camera and window info for debugging
        app.log.info(0, "=== Camera Setup ===");
        app.log.info(0, "Window size: " + app.WINDOW_WIDTH + "x" + app.WINDOW_HEIGHT);
        app.log.info(0, "Camera ortho: " + camera.ortho);
        app.log.info(0, "Camera zoom: " + camera.zoom);
        app.log.info(0, "Camera position: (" + camera.x + ", " + camera.y + ", " + camera.z + ")");
        
        trace("");
        trace("Press ESC to exit");
        trace("Press P to increase font size");
        trace("Press O to decrease font size");
    }
    
    /**
     * Public function to bake and display a font
     * Called from C# via BMFG_Export
     */
    public function loadAndBakeFont(fontPath:String, fontSize:Float):Void {
        app.log.info(0, 'loadAndBakeFont called with path: "$fontPath", size: $fontSize');
        
        try {
            // Update current settings
            this.fontPath = fontPath;
            this.currentFontSize = fontSize;
            
            // Generate output name from input font path (remove extension and path)
            // Handle both forward and back slashes
            var lastSlash = Std.int(Math.max(fontPath.lastIndexOf("/"), fontPath.lastIndexOf("\\")));
            var fileName = fontPath.substring(lastSlash + 1);
            app.log.info(0, 'Extracted fileName: "$fileName"');
            
            if (fileName.indexOf(".") > 0) {
                fileName = fileName.substring(0, fileName.lastIndexOf("."));
            }
            this.outputName = fileName + "_baked";
            app.log.info(0, 'Generated outputName: "$outputName"');
            
            // Remove old font entity if exists
            if (entities.length > 0) {
                app.log.info(0, 'Removing ${entities.length} old entities');
                var entity = entities[0];
                removeEntity(entity);
            }
            
            // Bake the font
            app.log.info(0, 'Starting font baking...');
            bakeFontAtSize(fontPath, fontSize, outputName);
            
            // Setup and display
            app.log.info(0, 'Starting font setup...');
            setupBakedFont(app.renderer, outputName);
        } catch (e:Dynamic) {
            app.log.error(0, 'Error in loadAndBakeFont: $e');
        }
    }
    
    /**
     * Bake font at specified size
     */
    private function bakeFontAtSize(fontPath:String, fontSize:Float, outputName:String):Void {
        var separator = "";
        for (i in 0...60) separator += "=";
        
        app.log.info(0, separator);
        app.log.info(0, 'Baking font at ${fontSize}px');
        app.log.info(0, '  Input: "$fontPath"');
        app.log.info(0, '  Output: "$outputName"');
        app.log.info(0, separator);
        
        try {
            // Bake font
            FontBaker.bakeFont(
                fontPath,  // Input TTF file
                outputName,          // Output name (without extension)
                fontSize,                   // Font size in pixels
                512,                        // Atlas width
                512,                        // Atlas height
                32,                         // First character (space)
                96                          // Number of characters (ASCII printable)
            );
            
            app.log.info(0, "Font baking complete!");
        } catch (e:Dynamic) {
            app.log.error(0, 'Font baking failed: $e');
            throw e;
        }
    }
    
    /**
     * Setup and display the baked font
     */
    private function setupBakedFont(renderer:Renderer, outputName:String):Void {
        app.log.info(0, "");
        app.log.info(0, "Loading baked font for display...");
        app.log.info(0, '  JSON path: "fonts/$outputName.json"');
        app.log.info(0, '  Texture path: "fonts/$outputName.tga"');
        
        // Load font JSON at runtime (not from cache)
        app.resources.loadText('fonts/$outputName.json', false).then((jsonText) -> {
            app.log.info(0, 'Font JSON loaded successfully, length: ${jsonText.length}');
            var fontData = FontLoader.load(jsonText);
            app.log.info(0, 'Font data parsed, characters: ${Lambda.count(fontData.chars)}');
            
            // Log font metrics for debugging
            if (fontData.chars.exists(65)) { // 'A' character
                var charA = fontData.chars.get(65);
                app.log.info(0, 'Sample char "A": width=${charA.width}, height=${charA.height}, advance=${charA.xadvance}');
            }
            app.log.info(0, 'Font metrics - base: ${fontData.base}, lineHeight: ${fontData.lineHeight}');
            
            // Load font texture at runtime (not from cache)
            app.resources.loadTexture('fonts/$outputName.tga', false).then((fontTextureData) -> {
                app.log.info(0, 'Font texture loaded: ${fontTextureData.width}x${fontTextureData.height}');
                
                var fontTexture = renderer.uploadTexture(fontTextureData);
                app.log.info(0, 'Font texture uploaded, ID: ${fontTexture.id}');
                
                // Create text shader
                app.log.info(0, "Loading text shaders...");
                var textVertShader = app.resources.getText("shaders/text.vert");
                app.log.info(0, 'text.vert loaded: ${textVertShader != null}, length=${textVertShader != null ? textVertShader.length : 0}');
                var textFragShader = app.resources.getText("shaders/text.frag");
                app.log.info(0, 'text.frag loaded: ${textFragShader != null}, length=${textFragShader != null ? textFragShader.length : 0}');
                var textProgramInfo = renderer.createProgramInfo("text", textVertShader, textFragShader);
                
                app.log.info(0, "Shader program created: " + (textProgramInfo != null));
                app.log.info(0, "Font texture ID: " + fontTexture.id);
                app.log.info(0, "Font texture size: " + fontTextureData.width + "x" + fontTextureData.height);
                
                // Create bitmap font
                app.log.info(0, "Creating BitmapFont...");
                bitmapFont = new BitmapFont(textProgramInfo, fontTexture, fontData);
                bitmapFont.init(renderer);
                
                app.log.info(0, "BitmapFont created, visible=" + bitmapFont.visible);
                
                // Create text to display
                var centerX = app.window.size.x / 2 - 150;
                var centerY = app.window.size.y / 2;
                
                // Round positions to whole pixels for pixel-perfect rendering
                centerX = Math.round(centerX);
                centerY = Math.round(centerY);
                
                app.log.info(0, "Window size: " + app.window.size.x + "x" + app.window.size.y);
                app.log.info(0, "Text position: (" + centerX + ", " + (centerY - 100) + ")");
                app.log.info(0, "Camera zoom: " + camera.zoom);
                
                displayText = new Text(bitmapFont, 
                    "Hello, World!\nBaked Font Test\nNokia FC22 @ " + Std.int(currentFontSize) + "px\n\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789\n!@#$%^&*()_+-=[]{}|;':,\",./<>?",
                    centerX, 
                    centerY - 100
                );
                
                app.log.info(0, "Text created, visible=" + displayText.visible);
                app.log.info(0, "Text size: " + displayText.width + "x" + displayText.height);
                app.log.info(0, "Tiles before buffer update: " + bitmapFont.getTileCount());
                app.log.info(0, "Atlas regions defined: " + Lambda.count(bitmapFont.atlasRegions));
                
                // Update buffers after adding text tiles
                bitmapFont.needsBufferUpdate = true;
                bitmapFont.updateBuffers(renderer);
                
                app.log.info(0, "Buffers updated");
                
                // Add font to scene using DisplayEntity (Text uses the font's tile batch)
                var fontEntity = new DisplayEntity(bitmapFont, "baked_font_display");
                addEntity(fontEntity);
                
                app.log.info(0, "Entity created, active=" + fontEntity.active + ", visible=" + fontEntity.visible);
                app.log.info(0, "DisplayObject visible=" + fontEntity.displayObject.visible);
                app.log.info(0, "Total entities in state: " + entities.length);
                
                app.log.info(0, "Baked font displayed successfully!");
                app.log.info(0, "BitmapFont has " + bitmapFont.getTileCount() + " tiles");
            }).onError((error) -> {
                app.log.error(0, "Failed to load font texture - " + error);
            });
        }).onError((error) -> {
            app.log.error(0, "Failed to load font data - " + error);
        });
    }
    
    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // Check for ESC to exit
        if (app.input.keyboard.pressed(Keycode.ESCAPE)) { // ESC key
            trace("FontBakerState: Exiting...");
            #if sys
            Sys.exit(0);
            #end
        }
        
        // Check for P key to increase font size (scancode 19 = 'P')
        if (app.input.keyboard.pressed(Keycode.P)) {
            currentFontSize += 1.0;
            if (currentFontSize > 64.0) currentFontSize = 64.0; // Max size
            trace("FontBakerState: Increasing font size to " + currentFontSize + "px");
            rebakeFont();
        }
        
        // Check for O key to decrease font size (scancode 18 = 'O')
        if (app.input.keyboard.pressed(Keycode.O)) {
            currentFontSize -= 1.0;
            if (currentFontSize < 4.0) currentFontSize = 4.0; // Min size
            trace("FontBakerState: Decreasing font size to " + currentFontSize + "px");
            rebakeFont();
        }
    }
    
    /**
     * Rebake font and reload it
     */
    private function rebakeFont():Void {
        // Remove old font entity
        if (entities.length > 0) {
            var entity = entities[0];
            removeEntity(entity);
        }
        
        // Rebake font with new size
        bakeFontAtSize(fontPath, currentFontSize, outputName);
        
        // Reload and display
        setupBakedFont(app.renderer, outputName);
    }
    
    private var renderFrameCount:Int = 0;
    
    override public function render(renderer:Renderer):Void {
        // Enable alpha blending for text transparency
        renderer.setBlendMode(true);
        
        // Only log first 3 frames to reduce spam
        if (renderFrameCount < 3) {
            if (bitmapFont != null) {
                trace("FontBakerState: DEBUG RENDER - Font tiles: " + bitmapFont.getTileCount() + ", visible: " + bitmapFont.visible);
            }
            
            var renderCount = 0;
            for (entity in entities) {
                if (entity != null && entity.active && entity.visible) {
                    renderCount++;
                }
            }
            trace("FontBakerState: DEBUG RENDER - Rendering " + renderCount + "/" + entities.length + " entities");
            renderFrameCount++;
        }
        
        super.render(renderer);
    }
}
