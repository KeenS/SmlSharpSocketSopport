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
          , ("hd o aliases is the same as name",
             fn () => (
                 let val entry = (Option.valOf (getByName "localhost"))
                 in assertEqualString (name entry) (List.hd (aliases entry)) end))
          , ("hd o addrs is the same as addr",
             fn () => (
                 let val entry = (Option.valOf (getByName "localhost"))
                 in assertEqualString (toString (addr entry)) (toString (List.hd (addrs entry))) end))
          (* , ("addrType is AF_INET4", *)
          (*    fn () => ( *)
          (*        let val entry = (Option.valOf (getByName "localhost")) *)
          (*        in assertTrue (familyEq (AF_INET, addrType entry)) *)
          (*        end)) *)
          , ("toString o fromString is identity when the address exists",
             fn () =>
                (assertEqualString "127.0.0.1" (toString (Option.valOf (fromString "127.0.0.1")))))

          , ("getByAddr o fromString  127.0.0.1 returns localhos",
             fn () =>
                (assertEqualString
                     "localhost"
                     (name (Option.valOf (getByAddr (Option.valOf (fromString "127.0.0.1")))))))

        ]
end
