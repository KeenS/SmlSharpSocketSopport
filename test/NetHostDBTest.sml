structure NetHostDBTest = struct
    open SMLUnit
    open NetHostDB
    open Assert
    fun println str = print (str ^ "\n")

    val suite = Test.labelTests [
            ("getHostName returns host name",
             fn () => (assertEqualString "T440p" (getHostName ())))
          , ("getByName localhost returns some",
             fn () => (assertSome (getByName "localhost")))
          , ("aliases o getByName localhost contains localhost",
             fn () => (assertTrue (List.exists (fn x => x = "localhost") (aliases (Option.valOf (getByName "localhost"))))))
        ]
end
