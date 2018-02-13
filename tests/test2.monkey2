#Import "<m2terminimal>"
#Import "<std>"
Using m2terminimal..
Using std..

Function Main()
	
	Local selection:Int
	Local maxSelection:Int=4
	
	While True
		Console.UpdateEvents()
		Console.Clear()
		
		If Console.KeyHit( $26 ) Then selection=selection-1
		If Console.KeyHit( $28 ) Then selection=(selection+1) Mod maxSelection
		If selection<0 Then selection=maxSelection-1
		
		Console.DrawBar( 3, 4+selection, 13 )
		
		Console.DrawText( "Selection 1", 4, 4 )
		Console.DrawText( "Selection 2", 4, 5 )
		Console.DrawText( "Selection 3", 4, 6 )
		Console.DrawText( "Selection 4", 4, 7 )
		
		If Console.KeyHit( 13 ) Then
			Console.DrawText( "You selected option #"+(selection+1), 17, 4+selection )
			Console.Render()
			Sleep( 1 )
		Else
			Console.Render()
		Endif
	Wend
	
	
End