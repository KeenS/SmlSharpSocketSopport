
structure NetHostDB :> NET_HOST_DB = struct

    open Common

    type in_addr_ = unit ptr
    type in_addr = (addr_family * in_addr_)

    type addrinfo = unit ptr


    type entry = {
        canonname: string,
        aliases: string list,
        addrType: addr_family,
        addrs: in_addr list
    }


    val c_to_string     = _import "sml_nhd_inaddr_to_string":(int, in_addr_, char ptr -> ()) -> ()
    val c_from_string   = _import "sml_nhd_inaddr_from_string": (string, int ref) -> in_addr_
    val c_get_addr      = _import "sml_nhd_addrinfo_get_addr": (addrinfo) -> in_addr_
    val c_get_canonname = _import "sml_nhd_addrinfo_get_canonname": (addrinfo) -> char ptr
    val c_get_next      = _import "sml_nhd_addrinfo_get_next": (addrinfo) -> addrinfo
    val c_get_family    = _import "sml_nhd_addrinfo_get_family": (addrinfo) -> int
    val c_free          = _import "sml_nhd_addrinfo_free": (addrinfo) -> ()
    val c_get_by_name   = _import "sml_nhd_get_by_name": (string) -> addrinfo
    val c_get_nameinfo  = _import "sml_nhd_get_nameinfo": (int, in_addr_, char ptr -> ()) -> ()
    val c_get_host_name = _import "sml_nhd_get_host_name": (char ptr -> ()) -> ()



    fun toString (family, in_addr) = let
        val ret = ref ""
    in
        c_to_string(familyToInt family, in_addr, (fn cptr => (ret := Pointer.importString cptr)));
        !ret
    end
    val name =  #canonname
    val aliases  = (fn x => x :: []) o name
    val addrType = #addrType
    val addrs = #addrs
    val addr  = List.hd o addrs

    fun getByName name = let
        val entry = c_get_by_name name
    in
        if Pointer.isNull entry
        then NONE
        else let
            val canonname = Pointer.importString (c_get_canonname entry)
            val aliases = []
            val topFamily = familyFromInt (c_get_family entry)
            fun loop entry acc = if Pointer.isNull entry
                                 then List.rev acc
                                 else let
                                     val family = familyFromInt (c_get_family entry)
                                     val addr = c_get_addr entry
                                     val next = c_get_next entry
                                 in loop next ((family, addr):: acc) end
            val addrs = loop entry []

        in
            c_free entry;
            SOME {addrType = topFamily, canonname = canonname, aliases = aliases, addrs = addrs}
        end
    end

    fun getByAddr (family, addr) = let
        val name = ref ""
        val () = c_get_nameinfo(familyToInt family, addr, (fn cptr => name := Pointer.importString cptr))
    in
        getByName (!name)
    end

    fun getHostName () = let
        val ret = ref ""
    in
        c_get_host_name (fn cptr => ret := Pointer.importString cptr);
        !ret
    end

    fun scan reader = raise Fail "unimplemented"
    fun fromString name = let
        val family = ref ~1
        val ret = c_from_string(name, family)
    in
        if Pointer.isNull ret
        then NONE
        else SOME (familyFromInt (!family), ret)
    end
end
