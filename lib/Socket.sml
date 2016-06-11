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
        type sock_type = int
        val SOCK_STREAM = (_import "socket_sock_stream": __attribute__((pure, fast)) () -> int)()
        val SOCK_DGRAM = (_import "socket_sock_dgram"  : __attribute__((pure, fast)) () -> int)()
        val stream = SOCK_STREAM
        val dgram  = SOCK_DGRAM
        fun list () = [
            ("STREAM", SOCK_STREAM),
            ("DGRAM", SOCK_DGRAM)
        ]
        fun toString socktype = #1 (Option.valOf (List.find (fn (name, s) => s = socktype) (list())))
        fun fromString str =  Option.map #2 (List.find (fn (name, s) => name = str) (list()))
    end

    structure Ctl = struct
        type optname = int
        val SO_DEBUG     = (_import "socket_ctl_debug"    : __attribute__((pure, fast)) () -> optname)()
        val SO_REUSEADDR = (_import "socket_ctl_reuseaddr": __attribute__((pure, fast)) () -> optname)()
        val SO_KEEPALIVE = (_import "socket_ctl_keepalive": __attribute__((pure, fast)) () -> optname)()
        val SO_DONTROUTE = (_import "socket_ctl_dontroute": __attribute__((pure, fast)) () -> optname)()
        val SO_LINGER    = (_import "socket_ctl_linger"   : __attribute__((pure, fast)) () -> optname)()
        val SO_BROADCAST = (_import "socket_ctl_broadcast": __attribute__((pure, fast)) () -> optname)()
        val SO_OOBINLINE = (_import "socket_ctl_oobinline": __attribute__((pure, fast)) () -> optname)()
        val SO_SNDBUF    = (_import "socket_ctl_sndbuf"   : __attribute__((pure, fast)) () -> optname)()
        val SO_RCVBUF    = (_import "socket_ctl_rcvbuf"   : __attribute__((pure, fast)) () -> optname)()
        val SO_TYPE      = (_import "socket_ctl_type"     : __attribute__((pure, fast)) () -> optname)()
        val SO_ERROR     = (_import "socket_ctl_error"    : __attribute__((pure, fast)) () -> optname)()

        val c_getsockopt = _import "socket_ctl_getsockopt": (('af, 'sock_type) sock, optname, int ref) -> int
        val c_setsockopt = _import "socket_ctl_setsockopt": (('af, 'sock_type) sock, optname, int) -> int
        val c_getsockopt_linger = _import "socket_ctl_getsockopt_linger": (('af, 'sock_type) sock, int ref) -> int
        val c_setsockopt_linger = _import "socket_ctl_setsockopt_linger": (('af, 'sock_type) sock, int) -> int
        val c_getpeername = _import "socket_ctl_getpeername": (('af, 'sock_type) sock, 'af sock_addr ref) -> int
        val c_getsockname = _import "socket_ctl_getsockname": (('af, 'sock_type) sock, 'af sock_addr ref) -> int
        val c_ioctl = _import "ioctl": (('af, 'sock_type) sock, word,  int ref) -> int
        val FIONREAD = (_import "socket_ctl_fionread":__attribute__((pure, fast)) () -> word)()
        val SIOCATMARK = (_import "socket_ctl_siocatmark":__attribute__((pure, fast)) () -> word)()

        fun genBoolOpt opt name = let
            fun get sock = let val ret = ref 0
                              in if c_getsockopt(sock, opt, ret) = 0
                                 then case !ret of 0 => false | _ => true
                                 else raise OS.SysErr("cannot get " ^ name, NONE)
                              end
            fun set (sock, v) = if c_setsockopt(sock, opt, if v then 1 else 0) = 0
                                 then ()
                                else raise OS.SysErr("cannot set " ^ name, NONE)
        in
            (get, set)
        end

        fun genIntOpt opt name = let
            fun get sock = let val ret = ref 0
                              in if c_getsockopt(sock, opt, ret) = 0
                                 then !ret
                                 else raise OS.SysErr("cannot get " ^ name, NONE)
                              end
            fun set (sock, v) = if c_setsockopt(sock, opt, v) = 0
                                 then ()
                                else raise OS.SysErr("cannot set " ^ name, NONE)
        in
            (get, set)
        end


        val (getDEBUG,     setDEBUG)     = genBoolOpt SO_DEBUG     "DEBUG"
        val (getREUSEADDR, setREUSEADDR) = genBoolOpt SO_REUSEADDR "REUSEADDR"
        val (getKEEPALIVE, setKEEPALIVE) = genBoolOpt SO_KEEPALIVE "KEEPALIVE"
        val (getDONTROUTE, setDONTROUTE) = genBoolOpt SO_DONTROUTE "DONTROUTE"
        val (getBROADCAST, setBROADCAST) = genBoolOpt SO_BROADCAST "BROADCAST"
        val (getOOBINLINE, setOOBINLINE) = genBoolOpt SO_OOBINLINE "OOBINLINE"

        fun getLINGER sock = let val ret = ref 0
                       in if c_getsockopt_linger(sock, ret) = 0
                          then case !ret of ~1 => NONE | linger => SOME(Time.fromSeconds(LargeInt.fromInt linger))
                          else raise OS.SysErr("cannot get " ^ "LINGER", NONE)
                       end
        fun setLINGER (sock, v) = if c_setsockopt_linger(sock, Option.getOpt(Option.map (fn t => (LargeInt.toInt(Time.toSeconds(t)))) v, ~1)) = 0
                            then ()
                            else raise OS.SysErr("cannot set " ^ "LINGER", NONE)

        val (getSNDBUF, setSNDBUF) = genIntOpt SO_SNDBUF "SNDBUF"
        val (getRCVBUF, setRCVBUF) = genIntOpt SO_RCVBUF "RCVBUF"

        fun getTYPE sock = let val ret = ref 0
                       in if c_getsockopt(sock, SO_TYPE, ret) = 0
                          then !ret
                          else raise OS.SysErr("cannot get " ^ "TYPE", NONE)
                       end
        fun getERROR sock = let val ret = ref 0
                       in if c_getsockopt(sock, SO_TYPE, ret) = 0
                          then case!ret of 0 => false | _ => true
                          else raise OS.SysErr("cannot get " ^ "ERROR", NONE)
                       end

        fun getPeerName sock = let
            val addr = ref (Pointer.NULL ())
        in
            if c_getpeername(sock, addr) = 0
            then !addr
            else raise OS.SysErr("cannot get peer name", NONE)
        end

        fun getSockName sock = let
            val addr = ref (Pointer.NULL ())
        in
            if c_getsockname(sock, addr) = 0
            then !addr
            else raise OS.SysErr("cannot get peer name", NONE)
        end

        fun getNREAD sock = let
            val ret = ref 0
        in if c_ioctl(sock, FIONREAD, ret) = 0
           then ! ret
           else raise OS.SysErr("cannot get NREAD", NONE)
        end

        fun getATMARK sock = let
            val ret = ref 0
        in if c_ioctl(sock, SIOCATMARK, ret) = 0
           then case ! ret of 0 => false | _  => true
           else raise OS.SysErr("cannot get ATMARK", NONE)
        end

    end

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

    val c_connect = _import "socket_connect": (('af, passive stream) sock, 'af sock_addr) -> int
    fun connect (sock, sa) = if c_connect (sock, sa) = 0
                          then ()
                          else raise OS.SysErr("failed to connect", NONE)

    val c_connect_nb = _import "socket_connect_nb": (('af, passive stream) sock, 'af sock_addr) -> int
    fun connectNB (sock, sa) =
      case c_connect_nb(sock, sa) of
          ~1 => raise OS.SysErr("failed to accept", NONE)
       |  ~2 => false
       | _ =>  true


    val c_close = _import "close": (('af, passive stream) sock) -> int
    fun close sock = case c_close(sock) of
                         0 => ()
                       | _ => raise OS.SysErr("failed to close", NONE)
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
