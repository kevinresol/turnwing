hello = Hello, { $name }!
empty = Hello, World!
bool =
    { -value -> 
        [0] { -no }
       *[1] { -yes }
    }
	
-yes = Yes
-no = No