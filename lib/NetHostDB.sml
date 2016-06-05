
structure NetHostDB = struct
    type in_addr = unit ptr

    datatype addr_family =
             AF_INET4
           | AF_INET6

    type addrinfo = unit ptr


    type entry = addrinfo

    fun familyFromInt 0 = AF_INET4
      | familyFromInt 1 = AF_INET6
      | familyFromInt _ = raise Fail "unknown address family returned from C"

    val c_to_string     = _import "sml_nhd_inaddr_to_string":(in_addr) -> char ptr
    val c_from_string   = _import "sml_nhd_inaddr_from_string": (string) -> in_addr
    val c_get_addr      = _import "sml_nhd_addrinfo_get_addr": (addrinfo) -> in_addr
    val c_get_canonname = _import "sml_nhd_addrinfo_get_canonname": (addrinfo) -> char ptr
    val c_get_next      = _import "sml_nhd_addrinfo_get_next": (addrinfo) -> addrinfo
    val c_get_family    = _import "sml_nhd_addrinfo_get_family": (addrinfo) -> int
    val c_free          = _import "sml_nhd_addrinfo_free": (addrinfo) -> ()
    val c_get_by_name   = _import "sml_nhd_get_by_name": (string) -> addrinfo
    val c_get_host_name = _import "sml_nhd_get_host_name": () -> char ptr


    fun entries entry = let
        fun loop entry acc = if Pointer.isNull entry
                             then List.rev acc
                             else let
                                 val next = c_get_next entry
                             in loop next (entry:: acc) end
        val entries = loop entry []

    in
        entries
    end


    val name = Pointer.importString o c_get_canonname
    val toString = Pointer.importString o c_to_string
    val aliases  = (fn x => x :: []) o name
    val addrType = familyFromInt o c_get_family
    val addr  = c_get_addr
    val addrs = List.map c_get_addr o entries

    fun getByName name = let
        val entry = c_get_by_name name
    in
        if Pointer.isNull entry
        then NONE
        else SOME entry
    end

    (* val getByAddr : in_addr -> entry option *)
    val getHostName : unit -> string = Pointer.importString o c_get_host_name

    (* val scan       : (char, 'a) StringCvt.reader *)
    (*                  -> (in_addr, 'a) StringCvt.reader *)
    fun fromString name = let
        val ret = c_from_string name
    in
        if Pointer.isNull ret
        then SOME ret
        else NONE
    end
end
