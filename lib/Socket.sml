structure Socket :> SOCKET
                        where type 'af sock_addr = unit ptr
                        where type ('af, 'sock_type) sock = int
= struct

    type 'af sock_addr = unit ptr
    type ('af,'sock_type) sock = int
    datatype dgram = DGRAM
    datatype 'mode stream = STREAM
    datatype passive = PASSIVE
    datatype active = ACTIVE

    structure AF = struct
        type addr_family = NetHostDB.addr_family
        val c_inet = _import "socket_af_inet": () -> int
        val c_inet6 = _import "socket_af_inet6": () -> int
        val c_unix = _import "socket_af_unix": () -> int
        fun list () = [
            ("INET", c_inet()),
            ("INET6", c_inet6()),
            ("UNIX", c_unix())
        ]
        fun toString family = #1 (Option.valOf (List.find (fn (name, f) => f = family) (list())))
        fun fromString str = Option.map #2 (List.find (fn (name, f) => name = str) (list()))
    end

    structure SOCK = struct
        datatype sock_type = SOCK_STREAM
                           | SOCK_DGRAM
        val stream = SOCK_STREAM
        val dgram  = SOCK_DGRAM
        fun list () = [
            ("STREAM", SOCK_STREAM),
            ("DGRAM", SOCK_DGRAM)
        ]
        fun toString socktype = #1 (Option.valOf (List.find (fn (name, s) => s = socktype) (list())))
        fun fromString str =  Option.map #2 (List.find (fn (name, s) => name = str) (list()))
    end

    (* structure Ctl : sig *)
    (*               val getDEBUG : ('af, 'sock_type) sock -> bool *)
    (*               val setDEBUG : ('af, 'sock_type) sock * bool -> unit *)
    (*               val getREUSEADDR : ('af, 'sock_type) sock -> bool *)
    (*               val setREUSEADDR : ('af, 'sock_type) sock * bool *)
    (*                                  -> unit *)
    (*               val getKEEPALIVE : ('af, 'sock_type) sock -> bool *)
    (*               val setKEEPALIVE : ('af, 'sock_type) sock * bool *)
    (*                                  -> unit *)
    (*               val getDONTROUTE : ('af, 'sock_type) sock -> bool *)
    (*               val setDONTROUTE : ('af, 'sock_type) sock * bool *)
    (*                                  -> unit *)
    (*               val getLINGER : ('af, 'sock_type) sock *)
    (*                               -> Time.time option *)
    (*               val setLINGER : ('af, 'sock_type) sock *)
    (*                               * Time.time option -> unit *)
    (*               val getBROADCAST : ('af, 'sock_type) sock -> bool *)
    (*               val setBROADCAST : ('af, 'sock_type) sock * bool *)
    (*                                  -> unit *)
    (*               val getOOBINLINE : ('af, 'sock_type) sock -> bool *)
    (*               val setOOBINLINE : ('af, 'sock_type) sock * bool *)
    (*                                  -> unit *)
    (*               val getSNDBUF : ('af, 'sock_type) sock -> int *)
    (*               val setSNDBUF : ('af, 'sock_type) sock * int -> unit *)
    (*               val getRCVBUF : ('af, 'sock_type) sock -> int *)
    (*               val setRCVBUF : ('af, 'sock_type) sock * int -> unit *)
    (*               val getTYPE : ('af, 'sock_type) sock -> SOCK.sock_type *)
    (*               val getERROR : ('af, 'sock_type) sock -> bool *)
    (*               val getPeerName : ('af, 'sock_type) sock *)
    (*                                 -> 'af sock_addr *)
    (*               val getSockName : ('af, 'sock_type) sock *)
    (*                                 -> 'af sock_addr *)
    (*               val getNREAD : ('af, 'sock_type) sock -> int *)
    (*               val getATMARK : ('af, active stream) sock -> bool *)
    (*           end *)

    val sameAddr = op=
    val c_family_of_addr = _import "socket_family_of_addr": ('af sock_addr) -> int
    val familyOfAddr = c_family_of_addr

    val c_bind = _import "socket_bind": (('af, 'sock_type) sock, 'af sock_addr) -> int
    fun bind (sock, sa) = let
        val ret = c_bind(sock, sa)
    in
        if ret = 0
        then ()
        else raise OS.SysErr("failed to bind", NONE)
    end

    val c_listen = _import "socket_listen": (('af, 'sock_type) sock, int) -> int
    fun listen ((sock: ('af, passive stream) sock), backlog) = let
        val ret = c_listen(sock, backlog)
    in
        if ret = 0
        then ()
        else raise OS.SysErr("failed to listen", NONE)
    end

    val c_accept = _import "socket_accept": (('af, passive stream) sock, 'af sock_addr ref) -> int

    fun accept (sock: ('af, passive stream) sock) = let
        val addr = ref (Pointer.NULL ())
        val ret = c_accept(sock, addr)
    in
        if ret = 0
        then (sock, !addr)
        else raise OS.SysErr("failed to accept", NONE)
    end

    val c_accept_nb = _import "socket_accept_nb": (('af, passive stream) sock, 'af sock_addr ref) -> ('af, passive stream) sock

    fun acceptNB (sock: ('af, passive stream) sock) = let
        val addr = ref (Pointer.NULL ())
        val ret = c_accept(sock, addr)
    in
        case ret of
            ~1 => raise OS.SysErr("failed to accept", NONE)
         |  ~2 => NONE
         | _ =>  SOME (ret, !addr)
    end

    (* val connect : ('af, 'sock_type) sock * 'af sock_addr *)
    (*               -> unit *)
    (* val connectNB : ('af, 'sock_type) sock * 'af sock_addr *)
    (*                 -> bool *)

    (* val close : ('af, 'sock_type) sock -> unit *)
    (* datatype shutdown_mode *)
    (*   = NO_RECVS *)
    (*   | NO_SENDS *)
    (*   | NO_RECVS_OR_SENDS *)
    (* val shutdown : ('af, 'mode stream) sock * shutdown_mode *)
    (*                -> unit *)

    (* type sock_desc *)
    (* val sockDesc : ('af, 'sock_type) sock -> sock_desc *)
    (* val sameDesc : sock_desc * sock_desc -> bool *)
    (* val select : { *)
    (*     rds : sock_desc list, *)
    (*     wrs : sock_desc list, *)
    (*     exs : sock_desc list, *)
    (*     timeout : Time.time option *)
    (* } *)
    (*              -> { *)
    (*         rds : sock_desc list, *)
    (*         wrs : sock_desc list, *)
    (*         exs : sock_desc list *)
    (*     } *)
    (* val ioDesc : ('af, 'sock_type) sock -> OS.IO.iodesc *)

    (* type out_flags = {don't_route : bool, oob : bool} *)
    (* type in_flags = {peek : bool, oob : bool} *)

    (* val sendVec : ('af, active stream) sock *)
    (*               * Word8VectorSlice.slice -> int *)
    (* val sendArr : ('af, active stream) sock *)
    (*               * Word8ArraySlice.slice -> int *)
    (* val sendVec' : ('af, active stream) sock *)
    (*                * Word8VectorSlice.slice *)
    (*                * out_flags -> int *)
    (* val sendArr' : ('af, active stream) sock *)
    (*                * Word8ArraySlice.slice *)
    (*                * out_flags -> int *)
    (* val sendVecNB  : ('af, active stream) sock *)
    (*                  * Word8VectorSlice.slice -> int option *)
    (* val sendVecNB' : ('af, active stream) sock *)
    (*                  * Word8VectorSlice.slice *)
    (*                  * out_flags -> int option *)
    (* val sendArrNB  : ('af, active stream) sock *)
    (*                  * Word8ArraySlice.slice -> int option *)
    (* val sendArrNB' : ('af, active stream) sock *)
    (*                  * Word8ArraySlice.slice *)
    (*                  * out_flags -> int option *)

    (* val recvVec  : ('af, active stream) sock * int *)
    (*                -> Word8Vector.vector *)
    (* val recvVec' : ('af, active stream) sock * int * in_flags *)
    (*                -> Word8Vector.vector *)
    (* val recvArr  : ('af, active stream) sock *)
    (*                * Word8ArraySlice.slice -> int *)
    (* val recvArr' : ('af, active stream) sock *)
    (*                * Word8ArraySlice.slice *)
    (*                * in_flags -> int *)
    (* val recvVecNB  : ('af, active stream) sock * int *)
    (*                  -> Word8Vector.vector option *)
    (* val recvVecNB' : ('af, active stream) sock * int * in_flags *)
    (*                  -> Word8Vector.vector option *)
    (* val recvArrNB  : ('af, active stream) sock *)
    (*                  * Word8ArraySlice.slice -> int option *)
    (* val recvArrNB' : ('af, active stream) sock *)
    (*                  * Word8ArraySlice.slice *)
    (*                  * in_flags -> int option *)

    (* val sendVecTo : ('af, dgram) sock *)
    (*                 * 'af sock_addr *)
    (*                 * Word8VectorSlice.slice -> unit *)
    (* val sendArrTo : ('af, dgram) sock *)
    (*                 * 'af sock_addr *)
    (*                 * Word8ArraySlice.slice -> unit *)
    (* val sendVecTo' : ('af, dgram) sock *)
    (*                  * 'af sock_addr *)
    (*                  * Word8VectorSlice.slice *)
    (*                  * out_flags -> unit *)
    (* val sendArrTo' : ('af, dgram) sock *)
    (*                  * 'af sock_addr *)
    (*                  * Word8ArraySlice.slice *)
    (*                  * out_flags -> unit *)
    (* val sendVecToNB  : ('af, dgram) sock *)
    (*                    * 'af sock_addr *)
    (*                    * Word8VectorSlice.slice -> bool *)
    (* val sendVecToNB' : ('af, dgram) sock *)
    (*                    * 'af sock_addr *)
    (*                    * Word8VectorSlice.slice *)
    (*                    * out_flags -> bool *)
    (* val sendArrToNB  : ('af, dgram) sock *)
    (*                    * 'af sock_addr *)
    (*                    * Word8ArraySlice.slice -> bool *)
    (* val sendArrToNB' : ('af, dgram) sock *)
    (*                    * 'af sock_addr *)
    (*                    * Word8ArraySlice.slice *)
    (*                    * out_flags -> bool *)

    (* val recvVecFrom  : ('af, dgram) sock * int *)
    (*                    -> Word8Vector.vector *)
    (*                       * 'sock_type sock_addr *)
    (* val recvVecFrom' : ('af, dgram) sock * int * in_flags *)
    (*                    -> Word8Vector.vector *)
    (*                       * 'sock_type sock_addr *)
    (* val recvArrFrom  : ('af, dgram) sock *)
    (*                    * Word8ArraySlice.slice *)
    (*                    -> int * 'af sock_addr *)
    (* val recvArrFrom' : ('af, dgram) sock *)
    (*                    * Word8ArraySlice.slice *)
    (*                    * in_flags -> int * 'af sock_addr *)
    (* val recvVecFromNB  : ('af, dgram) sock * int *)
    (*                      -> (Word8Vector.vector *)
    (*                          * 'sock_type sock_addr) option *)
    (* val recvVecFromNB' : ('af, dgram) sock * int * in_flags *)
    (*                      -> (Word8Vector.vector *)
    (*                          * 'sock_type sock_addr) option *)
    (* val recvArrFromNB  : ('af, dgram) sock *)
    (*                      * Word8ArraySlice.slice *)
    (*                      -> (int * 'af sock_addr) option *)
    (* val recvArrFromNB' : ('af, dgram) sock *)
    (*                      * Word8ArraySlice.slice *)
    (*                      * in_flags *)
    (*                      -> (int * 'af sock_addr) option  *)


end
