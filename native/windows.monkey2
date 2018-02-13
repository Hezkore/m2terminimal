Namespace m2terminimal

#Import "<windows.h>"

Private
	Global _defConsoleHandle:HANDLE
	Global _defInputHandle:HANDLE
	Global _lastNativeColor:Int
	Global _lastNativeBackground:Int
Public

Function InitConsole( console:ConsoleHandler )
	If Not console Then Print "NOPE!"
	
	' Create the main screen buffer
	_defConsoleHandle=CreateConsoleScreenBuffer( GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, Null, CONSOLE_TEXTMODE_BUFFER, Null )
	If Int(_defConsoleHandle)<=0 Then console.Alert( "Unable to create console screen buffer", True )
	
	' Switch to the main screen buffer
	SetConsoleActiveScreenBuffer( _defConsoleHandle )
	If GetLastError() Then console.Alert( "Unable to set console screen buffer", True )
	
	SetConsoleMode( _defConsoleHandle, 0 )
	If GetLastError()>0 And GetLastError()<>1150 Then
		console.Alert( "Unable to set console output mode "+GetLastError() )
	Endif
	
	' Set the main input buffer
	_defInputHandle=GetStdHandle( STD_INPUT_HANDLE )
	
End



Class ConsoleHandler Extension
	
	' Write text at cursor position
	Method native_plot( c:Int )
		WriteConsole( _defConsoleHandle, Varptr c, 1, Null, Null )
	End
	
	Method native_clear()
		
		Local c:COORD
		Local s:=native_windowsize
		
		c.X=s.X+1
		c.Y=s.Y+1
		SetConsoleScreenBufferSize( _defConsoleHandle, c )
		
		c.X=0
		c.Y=0
		Local written:DWORD
		
		native_cursorvisible=False
		
		' *1.25 is dirty but leaves a trail otherwise
		' Please fix
		FillConsoleOutputCharacter( _defConsoleHandle, 0, (s.Y*1.25)*s.X, c, Varptr written )
	End
	
	Method native_color( fg:Int, bg:Int )
		
		Select fg
			Case AnsiColor.Black _lastNativeColor=Null
			Case AnsiColor.White _lastNativeColor=FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE|FOREGROUND_INTENSITY
			Case AnsiColor.Red _lastNativeColor=FOREGROUND_RED|FOREGROUND_INTENSITY
			Case AnsiColor.Green _lastNativeColor=FOREGROUND_GREEN|FOREGROUND_INTENSITY
			Case AnsiColor.Blue _lastNativeColor=FOREGROUND_BLUE|FOREGROUND_INTENSITY
		End
		
		Select bg
			Case AnsiColor.Black _lastNativeBackground=Null
			Case AnsiColor.White _lastNativeColor=BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE|BACKGROUND_INTENSITY
			Case AnsiColor.Red _lastNativeBackground=BACKGROUND_RED|BACKGROUND_INTENSITY
			Case AnsiColor.Green _lastNativeBackground=BACKGROUND_GREEN|BACKGROUND_INTENSITY
			Case AnsiColor.Blue _lastNativeBackground=BACKGROUND_BLUE|BACKGROUND_INTENSITY
		End
		
		SetConsoleTextAttribute( _defConsoleHandle, _lastNativeColor|_lastNativeBackground )
	End
	
	Method native_input()
		
		Local input:=New INPUT_RECORD
		Local reads:DWORD
		
		' Do we have any event data?
		If Not PeekConsoleInput( _defInputHandle, Varptr input, 1, Varptr reads ) Then
			If GetLastError()>0 Then
				Alert( "Input error: "+GetLastError() )
				Return
			Endif
		Endif
		
		If input Then
			
			' We do!
			' Remove it from the stack
			If Not ReadConsoleInput( _defInputHandle, Varptr input, 1, Varptr reads ) Then
				If GetLastError()>0 Then
					Alert( "Input error: "+GetLastError() )
					Return
				Endif
			Endif
			
			' Keboard events
			If input.EventType=1 Then
				'Alert( "Input key: "+input.Event.KeyEvent.wVirtualKeyCode )
				'Return input.Event.KeyEvent.wVirtualKeyCode
				
				Local state:KeyState
				Local iState:UInt=input.Event.KeyEvent.dwControlKeyState
				
				If iState & $0080 Then state|=KeyState.Capslock
				If iState & $0100 Then state|=KeyState.Enhanced
				If iState & $0002 Then state|=KeyState.LeftAlt
				If iState & $0008 Then state|=KeyState.LeftCtrl
				If iState & $0020 Then state|=KeyState.Numlock
				If iState & $0001 Then state|=KeyState.RightAlt
				If iState & $0004 Then state|=KeyState.RightCtrl
				If iState & $0040 Then state|=KeyState.Scrolllock
				If iState & $0010 Then state|=KeyState.Shift
				
				' Key hit
				If input.Event.KeyEvent.bKeyDown Then
					_AddKeyHit( input.Event.KeyEvent.wVirtualKeyCode, state )
					_AddKeyDown( input.Event.KeyEvent.wVirtualKeyCode, state )
				Endif
				
				' Key up
				If Not input.Event.KeyEvent.bKeyDown Then
					_RemoveKeyDown( input.Event.KeyEvent.wVirtualKeyCode )
				Endif
				
			Endif
			
			' Scan for next event!
			native_input()
			Return
		Endif
		
	End
	
	' Set and Get window title
	Property native_title:String()
		'Local title:String
		'GetConsoleTitle( title, 0 )
		Return ""
	Setter( title:String )
		SetConsoleTitle( title )
	End
	
	' Set and Get cursor position
	Property native_cursorposition:Vec2i()
		Local info:CONSOLE_SCREEN_BUFFER_INFO
		GetConsoleScreenBufferInfo( _defConsoleHandle, Varptr info )
		Return New Vec2i( info.dwCursorPosition.X, info.dwCursorPosition.Y )
	Setter( pos:Vec2i )
		Local c:=New COORD
		c.X=pos.X
		c.Y=pos.Y
		SetConsoleCursorPosition( _defConsoleHandle, c )
	End
	
	Property native_windowsize:Vec2i()
		Local info:CONSOLE_SCREEN_BUFFER_INFO
		GetConsoleScreenBufferInfo( _defConsoleHandle, Varptr info )
		Return New Vec2i( info.srWindow.Right, info.srWindow.Bottom )
	End
	
	Property native_buffersize:Vec2i()
		Local info:CONSOLE_SCREEN_BUFFER_INFO
		GetConsoleScreenBufferInfo( _defConsoleHandle, Varptr info )
		Return New Vec2i( info.dwSize.X, info.dwSize.Y )
	End
	
	Property native_cursorvisible:Bool()
		Local c:CONSOLE_CURSOR_INFO
		GetConsoleCursorInfo( _defConsoleHandle, Varptr c )
		Return c.bVisible
	Setter( visible:Bool )
		Local c:CONSOLE_CURSOR_INFO
		GetConsoleCursorInfo( _defConsoleHandle, Varptr c )
		c.bVisible=visible
		
		SetConsoleCursorInfo( _defConsoleHandle, Varptr c )
	End
	
End

Extern
	Alias HANDLE:Void Ptr
	
	Struct DWORD
	End
	
	Struct TCHAR
	End
	
	Const ENABLE_WINDOW_INPUT:Int
	Const ENABLE_MOUSE_INPUT:Int
	Const STD_INPUT_HANDLE:Int
	Const FOREGROUND_BLUE:Int
	Const FOREGROUND_GREEN:Int
	Const FOREGROUND_RED:Int
	Const FOREGROUND_INTENSITY:Int
	Const BACKGROUND_BLUE:Int
	Const BACKGROUND_GREEN:Int
	Const BACKGROUND_RED:Int
	Const BACKGROUND_INTENSITY:Int
	Const COMMON_LVB_LEADING_BYTE:Int
	Const GENERIC_READ:Int
	Const GENERIC_WRITE:Int
	Const FILE_SHARE_READ:Int
	Const FILE_SHARE_WRITE:Int
	Const CONSOLE_TEXTMODE_BUFFER:Int
	
	Function SetConsoleTitle:Bool( title:CString )
	Function GetConsoleTitle:UInt( title:CString, nSize:UInt)
	Function GetConsoleScreenBufferInfo:Bool( hConsoleOutput:HANDLE, lpConsoleScreenBufferInfo:CONSOLE_SCREEN_BUFFER_INFO Ptr )
	Function GetStdHandle:HANDLE( nStdHandle:UInt )
	Function SetConsoleCursorPosition:Bool( hConsoleOutput:HANDLE, dwCursorPosition:COORD)
	Function SetConsoleTextAttribute:Bool( hConsoleOutput:HANDLE, wAttributes:Int )
	Function CreateConsoleScreenBuffer:HANDLE( dwDesiredAccess:UInt, dwShareMode:UInt, lpSecurityAttributes:UInt, dwFlags:UInt, Void Ptr )
	Function SetConsoleActiveScreenBuffer:Bool( hConsoleOutput:HANDLE)
	Function WriteConsole:Bool( output:HANDLE, buff:Void Ptr, length:UInt, written:DWORD Ptr, Void Ptr)
	Function GetLastError:UInt()
	Function SetConsoleMode:Bool( hConsoleHandle:HANDLE, dwMode:UInt)
	Function SetConsoleCursorInfo:Bool( hConsoleOutput:HANDLE, lpConsoleCursorInfo:CONSOLE_CURSOR_INFO Ptr )
	Function GetConsoleCursorInfo:Bool( hConsoleOutput:HANDLE, lpConsoleCursorInfo:CONSOLE_CURSOR_INFO Ptr )
	Function FillConsoleOutputCharacter:Bool( hConsoleOutput:HANDLE, cCharacter:Int, nLength:UInt, dwWriteCoord:COORD, lpNumberOfCharsWritten:DWORD Ptr )
	Function SetConsoleScreenBufferSize:Bool( hConsoleOutput:HANDLE, dwSize:COORD )
	Function ReadConsoleInput:Bool( hConsoleInput:HANDLE,  lpBuffer:INPUT_RECORD Ptr, nLength:UInt, lpNumberOfEventsRead:DWORD Ptr )
	Function PeekConsoleInput:Bool( hConsoleInput:HANDLE, lpBuffer:INPUT_RECORD Ptr, nLength:UInt, lpNumberOfEventsRead:DWORD Ptr )
	Function SetStdHandle:Bool( nStdHandle:UInt, hHandle:HANDLE )
	Function CFHANDLE:HANDLE( lpFileName:CString, dwDesiredAccess:UInt, dwShareMode:UInt, lpSecurityAttributes:UInt, dwCreationDisposition:UInt, dwFlagsAndAttributes:UInt, hTemplateFile:HANDLE )="CreateFile"
	
	Struct COORD
		Field X:Short
		Field Y:Short
	End
	
	Struct SMALL_RECT
		Field Left:Short
		Field Top:Short
		Field Right:Short
		Field Bottom:Short
	End
	
	Struct CONSOLE_SCREEN_BUFFER_INFO
		Field dwSize:COORD
		Field dwCursorPosition:COORD
		Field wAttributes:Int
		Field srWindow:SMALL_RECT
		Field dwMaximumWindowSize:COORD
	End
	
	Struct CONSOLE_CURSOR_INFO
		Field dwSize:UInt
		Field bVisible:Bool
	End
	
	Struct INPUT_RECORD
		Field EventType:Int
		Field Event:INPUT_EVENT
	End
	
	Struct INPUT_EVENT="event"
		Field KeyEvent:KEY_EVENT_RECORD
'		Field MouseEvent:MOUSE_EVENT_RECORD
'		Field WindowBufferSizeEvent:WINDOW_BUFFER_SIZE_RECORD
'		Field MenuEvent:MENU_EVENT_RECORD
'		Field FocusEvent:FOCUS_EVENT_RECORD
	End
	
	Struct KEY_EVENT_RECORD
	  Field bKeyDown:Bool
	  Field wRepeatCount:Int
	  Field wVirtualKeyCode:Int
	  Field wVirtualScanCode:Int
	  Field dwControlKeyState:UInt
	End
	
Public