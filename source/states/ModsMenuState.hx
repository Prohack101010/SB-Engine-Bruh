package states;

import backend.WeekData;
import backend.Mods;

import flixel.ui.FlxButton;
import flixel.FlxBasic;
import openfl.display.BitmapData;
import flash.geom.Rectangle;
import lime.utils.Assets;
import tjson.TJSON as Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import objects.AttachedSprite;

/*import haxe.zip.Reader;
import haxe.zip.Entry;
import haxe.zip.Uncompress;
import haxe.zip.Writer;*/

class ModsMenuState extends MusicBeatState
{
	var mods:Array<ModMetadata> = [];
	static var changedAThing = false;
	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var noModsTxt:FlxText;
	var selector:AttachedSprite;
	var descriptionTxt:FlxText;
	var needaReset = false;
	private static var currentlySelected:Int = 0;
	public static var defaultColor:FlxColor = 0xFF665AFF;

	var buttonDown:FlxButton;
	var buttonTop:FlxButton;
	var buttonDisableAll:FlxButton;
	var buttonEnableAll:FlxButton;
	var buttonUp:FlxButton;
	var buttonToggle:FlxButton;
	var buttonsArray:Array<FlxButton> = [];

	var installButton:FlxButton;
	var removeButton:FlxButton;

	var modsList:Array<Dynamic> = [];

	var visibleWhenNoMods:Array<FlxBasic> = [];
	var visibleWhenHasMods:Array<FlxBasic> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.setDirectoryFromWeek();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		noModsTxt = new FlxText(0, 0, FlxG.width, "NO MODS INSTALLED\nPRESS BACK TO EXIT AND INSTALL A MOD", 48);
		if(FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.'; //meanie
		noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noModsTxt.scrollFactor.set();
		noModsTxt.borderSize = 2;
		add(noModsTxt);
		noModsTxt.screenCenter();
		visibleWhenNoMods.push(noModsTxt);

		var list:ModsList = Mods.parseList();
		for (mod in list.all) modsList.push([mod, list.enabled.contains(mod)]);

		selector = new AttachedSprite();
		selector.xAdd = -205;
		selector.yAdd = -68;
		selector.alphaMult = 0.5;
		makeSelectorGraphic();
		add(selector);
		visibleWhenHasMods.push(selector);

		//attached buttons
		var startX:Int = 1120;

		buttonToggle = new FlxButton(startX, 0, "ON", function()
		{
			if(mods[currentlySelected].restart)
			{
				needaReset = true;
			}
			modsList[currentlySelected][1] = !modsList[currentlySelected][1];
			updateButtonToggle();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonToggle.setGraphicSize(50, 50);
		buttonToggle.updateHitbox();
		add(buttonToggle);
		buttonsArray.push(buttonToggle);
		visibleWhenHasMods.push(buttonToggle);

		buttonToggle.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		setAllLabelsOffset(buttonToggle, -15, 10);
		startX -= 70;

		buttonUp = new FlxButton(startX, 0, "/\\", function()
		{
			moveMod(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonUp.setGraphicSize(50, 50);
		buttonUp.updateHitbox();
		add(buttonUp);
		buttonsArray.push(buttonUp);
		visibleWhenHasMods.push(buttonUp);
		buttonUp.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK, CENTER);
		setAllLabelsOffset(buttonUp, -15, 10);
		startX -= 70;

		buttonDown = new FlxButton(startX, 0, "\\/", function() {
			moveMod(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDown.setGraphicSize(50, 50);
		buttonDown.updateHitbox();
		add(buttonDown);
		buttonsArray.push(buttonDown);
		visibleWhenHasMods.push(buttonDown);
		buttonDown.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK, CENTER);
		setAllLabelsOffset(buttonDown, -15, 10);

		startX -= 100;
		buttonTop = new FlxButton(startX, 0, "TOP", function() {
			var doRestart:Bool = (mods[0].restart || mods[currentlySelected].restart);
			for (i in 0...currentlySelected) //so it shifts to the top instead of replacing the top one
			{
				moveMod(-1, true);
			}

			if(doRestart)
			{
				needaReset = true;
			}
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonTop.setGraphicSize(80, 50);
		buttonTop.updateHitbox();
		buttonTop.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK, CENTER);
		setAllLabelsOffset(buttonTop, 0, 10);
		add(buttonTop);
		buttonsArray.push(buttonTop);
		visibleWhenHasMods.push(buttonTop);


		startX -= 190;
		buttonDisableAll = new FlxButton(startX, 0, "DISABLE ALL", function() {
			for (i in modsList)
			{
				i[1] = false;
			}
			for (mod in mods)
			{
				if (mod.restart)
				{
					needaReset = true;
					break;
				}
			}
			updateButtonToggle();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDisableAll.setGraphicSize(170, 50);
		buttonDisableAll.updateHitbox();
		buttonDisableAll.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK, CENTER);
		buttonDisableAll.label.fieldWidth = 170;
		setAllLabelsOffset(buttonDisableAll, 0, 10);
		add(buttonDisableAll);
		buttonsArray.push(buttonDisableAll);
		visibleWhenHasMods.push(buttonDisableAll);

		startX -= 190;
		buttonEnableAll = new FlxButton(startX, 0, "ENABLE ALL", function() {
			for (i in modsList)
			{
				i[1] = true;
			}
			for (mod in mods)
			{
				if (mod.restart)
				{
					needaReset = true;
					break;
				}
			}
			updateButtonToggle();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonEnableAll.setGraphicSize(170, 50);
		buttonEnableAll.updateHitbox();
		buttonEnableAll.label.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.BLACK, CENTER);
		buttonEnableAll.label.fieldWidth = 170;
		setAllLabelsOffset(buttonEnableAll, 0, 10);
		add(buttonEnableAll);
		buttonsArray.push(buttonEnableAll);
		visibleWhenHasMods.push(buttonEnableAll);

		// more buttons
		var startX:Int = 1100;

		/*
		installButton = new FlxButton(startX, 620, "Install Mod", function()
		{
			installMod();
		});
		installButton.setGraphicSize(150, 70);
		installButton.updateHitbox();
		installButton.color = FlxColor.GREEN;
		installButton.label.fieldWidth = 135;
		installButton.label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		setAllLabelsOffset(installButton, 2, 24);
		add(installButton);
		startX -= 180;

		removeButton = new FlxButton(startX, 620, "Delete Selected Mod", function()
		{
			var path = haxe.io.Path.join([Paths.mods(), modsList[currentlySelected][0]]);
			if(FileSystem.exists(path) && FileSystem.isDirectory(path))
			{
				trace('Trying to delete directory ' + path);
				try
				{
					FileSystem.deleteFile(path); //FUCK YOU HAXE WHY DONT YOU WORK WAAAAAAAAAAAAH

					var icon = mods[currentlySelected].icon;
					var alphabet = mods[currentlySelected].alphabet;
					remove(icon);
					remove(alphabet);
					icon.destroy();
					alphabet.destroy();
					modsList.remove(modsList[currentlySelected]);
					mods.remove(mods[currentlySelected]);

					if(currentlySelected >= mods.length) --currentlySelected;
					changeSelection();
				}
				catch(e)
				{
					trace('Error deleting directory: ' + e);
				}
			}
		});
		removeButton.setGraphicSize(150, 70);
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.fieldWidth = 135;
		removeButton.label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		setAllLabelsOffset(removeButton, 2, 15);
		add(removeButton);
		visibleWhenHasMods.push(removeButton);*/

		///////
		descriptionTxt = new FlxText(148, 0, FlxG.width - 216, "", 32);
		descriptionTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
		descriptionTxt.scrollFactor.set();
		add(descriptionTxt);
		visibleWhenHasMods.push(descriptionTxt);

		var i:Int = 0;
		var len:Int = modsList.length;
		while (i < modsList.length)
		{
			var values:Array<Dynamic> = modsList[i];
			if(!FileSystem.exists(Paths.mods(values[0])))
			{
				modsList.remove(modsList[i]);
				continue;
			}

			var newMod:ModMetadata = new ModMetadata(values[0]);
			mods.push(newMod);

			newMod.alphabet = new Alphabet(0, 0, mods[i].name, true);
			var scale:Float = Math.min(840 / newMod.alphabet.width, 1);
			newMod.alphabet.setScale(scale);
			newMod.alphabet.y = i * 150;
			newMod.alphabet.x = 310;
			add(newMod.alphabet);
			//Don't ever cache the icons, it's a waste of loaded memory
			var loadedIcon:BitmapData = null;
			var iconToUse:String = Paths.mods(values[0] + '/pack.png');
			if(FileSystem.exists(iconToUse))
			{
				loadedIcon = BitmapData.fromFile(iconToUse);
			}

			newMod.icon = new AttachedSprite();
			if(loadedIcon != null)
			{
				newMod.icon.loadGraphic(loadedIcon, true, 150, 150);//animated icon support
				var totalFrames = Math.floor(loadedIcon.width / 150) * Math.floor(loadedIcon.height / 150);
				newMod.icon.animation.add("icon", [for (i in 0...totalFrames) i],10);
				newMod.icon.animation.play("icon");
			}
			else
			{
				newMod.icon.loadGraphic(Paths.image('unknownMod'));
			}
			newMod.icon.sprTracker = newMod.alphabet;
			newMod.icon.xAdd = -newMod.icon.width - 30;
			newMod.icon.yAdd = -45;
			add(newMod.icon);
			i++;
		}

		if(currentlySelected >= mods.length) currentlySelected = 0;

		if(mods.length < 1)
			bg.color = defaultColor;
		else
			bg.color = mods[currentlySelected].color;

		intendedColor = bg.color;
		changeSelection();
		updatePosition();
		FlxG.sound.play(Paths.sound('scrollMenu'));

		FlxG.mouse.visible = true;

    #if mobile
    addVirtualPad(UP_DOWN, B);
    #end

		super.create();
	}

	/*function getIntArray(max:Int):Array<Int>{
		var arr:Array<Int> = [];
		for (i in 0...max) {
			arr.push(i);
		}
		return arr;
	}*/
	function updateButtonToggle()
	{
		if (modsList[currentlySelected][1])
		{
			buttonToggle.label.text = 'ON';
			buttonToggle.color = FlxColor.GREEN;
		}
		else
		{
			buttonToggle.label.text = 'OFF';
			buttonToggle.color = FlxColor.RED;
		}
	}

	function moveMod(change:Int, skipResetCheck:Bool = false)
	{
		if(mods.length > 1)
		{
			var doRestart:Bool = (mods[0].restart);

			var newPos:Int = currentlySelected + change;
			if(newPos < 0)
			{
				modsList.push(modsList.shift());
				mods.push(mods.shift());
			}
			else if(newPos >= mods.length)
			{
				modsList.insert(0, modsList.pop());
				mods.insert(0, mods.pop());
			}
			else
			{
				var lastArray:Array<Dynamic> = modsList[currentlySelected];
				modsList[currentlySelected] = modsList[newPos];
				modsList[newPos] = lastArray;

				var lastMod:ModMetadata = mods[currentlySelected];
				mods[currentlySelected] = mods[newPos];
				mods[newPos] = lastMod;
			}
			changeSelection(change);

			if(!doRestart) doRestart = mods[currentlySelected].restart;
			if(!skipResetCheck && doRestart) needaReset = true;
		}
	}

	function saveTxt()
	{
		var fileStr:String = '';
		for (values in modsList)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		var path:String = SUtil.getPath() + 'modsList.txt';
		File.saveContent(path, fileStr);
		Mods.pushGlobalMods();
	}

	var noModsSine:Float = 0;
	var canExit:Bool = true;
	override function update(elapsed:Float)
	{
		if(noModsTxt.visible)
		{
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
		}

		if(canExit && controls.BACK)
		{
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.mouse.visible = false;
			saveTxt();
			if(needaReset)
			{
				//MusicBeatState.switchState(new TitleState());
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.sound.music.fadeOut(0.3);
				if(FreeplayState.vocals != null)
				{
					FreeplayState.vocals.fadeOut(0.3);
					FreeplayState.vocals = null;
				}
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
			}
			else
			{
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(controls.UI_UP_P)
		{
			changeSelection(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		if(controls.UI_DOWN_P)
		{
			changeSelection(1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		updatePosition(elapsed);
		super.update(elapsed);
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	function changeSelection(change:Int = 0)
	{
		var noMods:Bool = (mods.length < 1);
		for (obj in visibleWhenHasMods)
		{
			obj.visible = !noMods;
		}
		for (obj in visibleWhenNoMods)
		{
			obj.visible = noMods;
		}
		if(noMods) return;

		currentlySelected += change;
		if(currentlySelected < 0)
			currentlySelected = mods.length - 1;
		else if(currentlySelected >= mods.length)
			currentlySelected = 0;

		var newColor:Int = mods[currentlySelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var i:Int = 0;
		for (mod in mods)
		{
			mod.alphabet.alpha = 0.6;
			if(i == currentlySelected)
			{
				mod.alphabet.alpha = 1;
				selector.sprTracker = mod.alphabet;
				descriptionTxt.text = mod.description;
				if (mod.restart){//finna make it to where if nothing changed then it won't reset
					descriptionTxt.text += " (This Mod will restart the game!)";
				}

				// correct layering
				var stuffArray:Array<FlxSprite> = [/*removeButton, installButton,*/ selector, descriptionTxt, mod.alphabet, mod.icon];
				for (obj in stuffArray)
				{
					remove(obj);
					insert(members.length, obj);
				}
				for (obj in buttonsArray)
				{
					remove(obj);
					insert(members.length, obj);
				}
			}
			i++;
		}
		updateButtonToggle();
	}

	function updatePosition(elapsed:Float = -1)
	{
		var i:Int = 0;
		for (mod in mods)
		{
			var intendedPos:Float = (i - currentlySelected) * 225 + 200;
			if(i > currentlySelected) intendedPos += 225;
			if(elapsed == -1)
			{
				mod.alphabet.y = intendedPos;
			}
			else
			{
				mod.alphabet.y = FlxMath.lerp(mod.alphabet.y, intendedPos, FlxMath.bound(elapsed * 12, 0, 1));
			}

			if(i == currentlySelected)
			{
				descriptionTxt.y = mod.alphabet.y + 160;
				for (button in buttonsArray)
				{
					button.y = mod.alphabet.y + 320;
				}
			}
			i++;
		}
	}

	var cornerSize:Int = 11;
	function makeSelectorGraphic()
	{
		selector.makeGraphic(1100, 450, FlxColor.BLACK);
		selector.pixels.fillRect(new Rectangle(0, 190, selector.width, 5), 0x0);

		// Why did i do this? Because i'm a lmao stupid, of course
		// also i wanted to understand better how fillRect works so i did this shit lol???
		selector.pixels.fillRect(new Rectangle(0, 0, cornerSize, cornerSize), 0x0);														 //top left
		drawCircleCornerOnSelector(false, false);
		selector.pixels.fillRect(new Rectangle(selector.width - cornerSize, 0, cornerSize, cornerSize), 0x0);							 //top right
		drawCircleCornerOnSelector(true, false);
		selector.pixels.fillRect(new Rectangle(0, selector.height - cornerSize, cornerSize, cornerSize), 0x0);							 //bottom left
		drawCircleCornerOnSelector(false, true);
		selector.pixels.fillRect(new Rectangle(selector.width - cornerSize, selector.height - cornerSize, cornerSize, cornerSize), 0x0); //bottom right
		drawCircleCornerOnSelector(true, true);
	}

	function drawCircleCornerOnSelector(flipX:Bool, flipY:Bool)
	{
		var antiX:Float = (selector.width - cornerSize);
		var antiY:Float = flipY ? (selector.height - 1) : 0;
		if(flipY) antiY -= 2;
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 1), Std.int(Math.abs(antiY - 8)), 10, 3), FlxColor.BLACK);
		if(flipY) antiY += 1;
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 2), Std.int(Math.abs(antiY - 6)),  9, 2), FlxColor.BLACK);
		if(flipY) antiY += 1;
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 3), Std.int(Math.abs(antiY - 5)),  8, 1), FlxColor.BLACK);
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 4), Std.int(Math.abs(antiY - 4)),  7, 1), FlxColor.BLACK);
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 5), Std.int(Math.abs(antiY - 3)),  6, 1), FlxColor.BLACK);
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 6), Std.int(Math.abs(antiY - 2)),  5, 1), FlxColor.BLACK);
		selector.pixels.fillRect(new Rectangle((flipX ? antiX : 8), Std.int(Math.abs(antiY - 1)),  3, 1), FlxColor.BLACK);
	}

	/*var _file:FileReference = null;
	function installMod() {
		var zipFilter:FileFilter = new FileFilter('ZIP', 'zip');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([zipFilter]);
		canExit = false;
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null)
		{
			var rawZip:String = File.getContent(fullPath);
			if(rawZip != null)
			{
				MusicBeatState.resetState();
				var uncompressingFile:Bytes = new Uncompress().run(File.getBytes(rawZip));
				if (uncompressingFile.done)
				{
					trace('test');
					_file = null;
					return;
				}
			}
		}
		_file = null;
		canExit = true;
		trace("File couldn't be loaded! Wtf?");
	}

	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		canExit = true;
		trace("Cancelled file loading.");
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		canExit = true;
		trace("Problem loading file");
	}*/
}

class ModMetadata
{
	public var folder:String;
	public var name:String;
	public var description:String;
	public var color:FlxColor;
	public var restart:Bool;//trust me. this is very important
	public var alphabet:Alphabet;
	public var icon:AttachedSprite;

	public function new(folder:String)
	{
		this.folder = folder;
		this.name = folder;
		this.description = "No description provided.";
		this.color = ModsMenuState.defaultColor;
		this.restart = false;

		//Try loading json
		var pack:Dynamic = Mods.getPack(folder);
		if(pack != null) {
			if(pack.name != null && pack.name.length > 0)
			{
				if(pack.name != 'Name')
					this.name = pack.name;
				else
					this.name = pack.folder;
			}

			if(pack.description != null && pack.description.length > 0)
			{
				if(pack.description != 'Description')
					this.description = pack.description;
				else
					this.description = "No description provided.";
			}

			if(pack.color != null)
				this.color = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170,
											pack.color[1] != null ? pack.color[1] : 0,
											pack.color[2] != null ? pack.color[2] : 255);
			this.restart = pack.restart;
		}
	}
}
