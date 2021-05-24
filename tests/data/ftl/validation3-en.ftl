hello = Hello, { $name }!
empty = Hello, World!
bool =
    { $value -> 
        [0] { -empty -> 
                 [no] { -no }
                *[yes] { -yes }
            }
       *[1] { -yes }
    }
	
-yes = Yes
-no = No