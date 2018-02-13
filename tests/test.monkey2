#Import "<m2terminimal>"
#Import "<std>"
Using m2terminimal..
Using std..

Function Main()
	
	Local yOffset:Int
	
	While True
		Console.UpdateSize()
		Console.UpdateEvents()
		Console.Clear()
		
		Console.Color=AnsiColor.White
		Console.Background=AnsiColor.Black
		
		For Local x:=0 Until Console.Size().X
			Console.DrawText( "*", x, 0 )
			Console.DrawText( "*", x, Console.Size().Y-1 )
		Next
		
		For Local y:=0 Until Console.Size().Y
			Console.DrawText( "*", 0, y )
			Console.DrawText( "*", Console.Size().X-1, y )
		Next
		
		Console.Color=AnsiColor.Red
		Console.Background=AnsiColor.Green
		Console.DrawText( "w"+Console.Size(), 3,3+yOffset )
		
		Console.Background=AnsiColor.Red
		Console.Color=AnsiColor.Green
		
		'Console.DrawText( "b"+Console.native_buffersize, 4,4 )
'		Console.DrawText( "s"+Console._sameFrames, 5,5 )
'		Console.DrawText( "d"+Console._diffFrames/10, 6,6 )
		Console.DrawText( "Hello World 12345678901234567890", Millisecs()*0.01-38, yOffset )
		Console.DrawText( "Bye World", Millisecs()*0.005, 1+yOffset )
		
		
		'Console.DrawBar( 0, Console.Size().Y-1 )
		
		Console.DrawRect( 8, 8, 1, 1 )
		
		'Console._CursorPosition=New Vec2i(0,0)
		'Console.Write( "w:"+Console.WindowSize.X+"~n" )
		'Console.Write( "h:"+Console.WindowSize.Y+"~n" )
		
		If Console.KeyHit( $26 ) Then yOffset-=1
		If Console.KeyHit( $28 ) Then yOffset+=1
		Console.Input( "Write something> ", 0, Console.Size().Y-1 )
		
		Console.Render()
		
		'Sleep(0.5)
	Wend
End