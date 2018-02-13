Namespace m2terminimal

#Import "<std>"
Using std..

#If __TARGET__="windows"
	#Import "native/windows"
#ElseIf __TARGET__="linux"
	
#ElseIf __TARGET__="macos"
	
#Endif

Global Console:=New ConsoleHandler

Enum AnsiColor
	Black=30,Red,Green,Yellow,Blue,Magenta,Cyan,White
End

Class ConsoleHandler
	
	Struct Char
		Field _code:UInt
		Field _fg:Int
		Field _bg:Int
	End
	
	Struct InputKey
		Field Code:UInt
		Field State:KeyState
		
		Method Ascii:String()
			If Code=32 Then Return " "
			
			If Code>=65 And Code<=90 Then
				If State & KeyState.Capslock Or State & KeyState.Shift Then
					Return String.FromChar( Code )
				Else
					Return String.FromChar( Code+32 )
				Endif
			Endif
			
			Return ""
		End
	End
	
	Enum KeyState
		Capslock=$0080
		Enhanced=$0100
		LeftAlt=$0002
		LeftCtrl=$0008
		Numlock=$0020
		RightAlt=$0001
		RightCtrl=$0004
		Scrolllock=$0040
		Shift=$0010
	End
	
	Method New()
		InitConsole( Self )
		UpdateSize()
	End
	
	Property CursorVisible:Bool()
		Return _curVisible
	Setter( visible:Bool )
		_curVisible=visible
	End
	
	Property Color:Int()
		Return _color
	Setter( color:Int )
		_color=color
	End
	
	Property Background:Int()
		Return _background
	Setter( background:Int )
		_background=background
	End
	
	Method Alert( msg:String, error:Bool=False, char:Int=176 )
		If error Then
			msg="ERROR "+msg
		Else
			msg="ALERT "+msg
		Endif
		
		Print msg
		
		native_cursorposition=New Vec2i(0,0)
		
		For Local x:Int=0 To _bufferWidth
			native_plot(char)
		Next
		
		native_cursorposition=New Vec2i(_bufferWidth/2-msg.Length/2,0)
		For Local x:Int=0 Until msg.Length
			native_plot(msg[x])
		Next
		
		Local delay:=Millisecs()+2500
		Repeat
			If Not error And Millisecs()>delay Then
				Exit
			Endif
		Forever
		
		For Local x:Int=0 Until _bufferWidth
			If x>=_frontBuffer.Length Then Exit
			_frontBuffer[x]._code=char
		Next
	End
	
	Method Size:Vec2i()
		Return New Vec2i( _bufferWidth, _bufferHeight )
	End
	
	Method UpdateSize()
		Local w:=native_windowsize.X+1
		Local h:=native_windowsize.Y+1
		
		If _bufferWidth=w And _bufferHeight=h Then Return
		_bufferWidth=w
		_bufferHeight=h
		
		If _frontBuffer.Length>0 Then native_clear()
		
		_backBuffer=_backBuffer.Resize( _bufferHeight*_bufferWidth )
		_frontBuffer=New Char[_backBuffer.Length]
		_lastBackBuffer=New Char[_backBuffer.Length]
	End
	
	Method TranslatePos:Int( x:Int, y:Int )
		If y>=_bufferHeight Then y=_bufferHeight-1
		Return (y*_bufferWidth)+x
	End
	
	Method Input( text:String, x:Float, y:Float )
		Local asc:String
		
		CursorPosition=New Vec2i( x+text.Length+_inputText.Length-_inputCursor, y )
		CursorVisible=True
		
		For Local k:=Eachin _keysHit
			
			' Backspace
			If k.Code=8 And _inputText.Length-_inputCursor>0 Then
				If _inputCursor Then
					_inputText=_inputText.Left( _inputText.Length-_inputCursor-1 )+_inputText.Right( _inputCursor )
				Else
					_inputText=_inputText.Slice( 0, -1 )
				Endif
				
				Continue
			Endif
			
			' Delete
			If k.Code=46 And _inputCursor Then
				If _inputCursor>1 Then 
					_inputText=_inputText.Left( _inputText.Length-_inputCursor )+_inputText.Right( _inputCursor-1  )
				Else
					_inputText=_inputText.Slice( 0, -1 )
				Endif
				_inputCursor-=1
				
				Continue
			Endif
			
			' Left
			If k.Code=37 Then
				If _inputCursor<_inputText.Length Then _inputCursor+=1
				Continue
			Endif
			
			' Right
			If k.Code=39 Then
				If _inputCursor>0 Then _inputCursor-=1
				Continue
			Endif
			
			asc=k.Ascii()
			If asc Then 
				If _inputCursor Then
					_inputText=_inputText.Left( _inputText.Length-_inputCursor )+asc+_inputText.Right( _inputCursor )
				Else
					_inputText+=asc
				Endif
				Continue
			Endif
		Next
		
		If _inputCursor>_inputText.Length Then _inputCursor=_inputText.Length
		
		DrawText( text+_inputText, x, y )
	End
	
	Property CursorPosition:Vec2i()
		Return _curPos
	Setter( pos:Vec2i )
		If pos<>_curPos Then _curPos=pos
	End
	
	Method DrawText( text:String, x:Float, y:Float )
		' Will the text even be visible?
		If text.Length<=0 Then Return
		If x+text.Length<0 Or x>=_bufferWidth Then Return
		If y<0 Or y>=_bufferHeight Then Return
		
		For Local i:=0 Until text.Length
			If x<0 Then
				x+=1
				Continue
			Else
				If x>=_bufferWidth Then Exit
			Endif
			Plot( text[i], x, y )
			x+=1
		Next
	End
	
	Method DrawRect( x:Float, y:Float, width:Int, height:Int, char:Int=219 )
		If width=0 Or height=0 Then Return
		
		For Local dy:=y Until y+height
		For Local dx:=x Until x+width
			
			If dx<0 Or dx>=_bufferWidth Then Continue
			If dy<0 Or dy>=_bufferHeight Then Continue
			
			Plot( char, dx, dy )
		Next
		Next
	End
	
	Method Plot( charCode:UInt, x:Float, y:Float )
		Local pos:Int=TranslatePos( x, y )
		_backBuffer[pos]._code=charCode
		_backBuffer[pos]._fg=_color
		_backBuffer[pos]._bg=_background
	End
	
	Method Clear()
		For Local i:=0 Until _backBuffer.Length
			_backBuffer[i]._code=0
			_backBuffer[i]._fg=AnsiColor.White
			_backBuffer[i]._bg=AnsiColor.Black
		Next
	End
	
	Method KeyHit:Bool( key:Int )
		For Local k:=Eachin _keysHit
			If k.Code=key Then Return True
		Next
		Return False
	End
	
	Method KeyDown:Bool( key:Int )
		For Local k:=Eachin _keysDown
			If k.Code=key Then Return True
		Next
		Return False
	End
	
	Method Render()
		' Do we even need to redraw?
		Local needsRedraw:Bool=False
		
		For Local i:=0 Until _backBuffer.Length
			If _backBuffer[i]<>_lastBackBuffer[i] Then
				needsRedraw=True
				_diffFrames+=1
				Exit
			Endif
		Next
		
		' Do not need redraw
		If Not needsRedraw Then
			_sameFrames+=1
			Return
		Endif
		
		' Needs redraw
		Local x:Int
		Local y:Int
		
		native_cursorvisible=False
		
		For Local i:=0 Until _backBuffer.Length
			_lastBackBuffer[i]=_backBuffer[i]
			
			If x>=_bufferWidth Then
				x=0
				y+=1
			Endif
			
			If _backBuffer[i]<>_frontBuffer[i] Then
				
				native_cursorposition=New Vec2i( x, y )
				
				If _lastColor<>_backBuffer[i]._fg Or _lastBackground<>_backBuffer[i]._bg Then
					_lastColor=_backBuffer[i]._fg
					_lastBackground=_backBuffer[i]._bg
					
					native_color( _lastColor, _lastBackground )
				Endif
				
				native_plot( _backBuffer[i]._code )
				
				_frontBuffer[i]=_backBuffer[i]
			Endif
			
			x+=1
		Next
		
		If _curVisible Then
			native_cursorvisible=True
			If native_cursorposition<>_curPos Then
				native_cursorposition=_curPos
			Endif
		Endif
	End
	
	Method UpdateEvents()
		_keysHit.Clear()
		native_input()
	End
	
	Private
		Field _lastBackBuffer:Char[]
		Field _backBuffer:Char[]
		Field _frontBuffer:Char[]
		Field _bufferWidth:Int
		Field _bufferHeight:Int
		Field _curVisible:Bool'=True
		Field _curPos:Vec2i
		Field _keysHit:=New Stack<InputKey>
		Field _keysDown:=New Stack<InputKey>
		Field _sameFrames:UInt
		Field _diffFrames:UInt
		Field _inputText:String
		Field _inputCursor:UInt
		Field _color:Int=AnsiColor.White
		Field _lastColor:Int
		Field _background:Int=AnsiColor.Blue
		Field _lastBackground:Int
	Public
	
	Method _AddKeyHit( key:UInt, state:KeyState )
		Local k:=New InputKey
		k.Code=key
		k.State=state
		_keysHit.Add( k )
	End
	
	Method _AddKeyDown( key:UInt, state:KeyState )
		Local k:=New InputKey
		k.Code=key
		k.State=state
		_keysDown.Add( k )
	End
	
	Method _RemoveKeyDown( key:UInt )
		For Local i:=0 Until _keysDown.Length
			If _keysDown[i].Code=key Then
				_keysDown.Erase( i )
			Endif
		Next
	End
	
End