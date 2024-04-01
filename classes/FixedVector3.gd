@tool
extends Resource
class_name FixedVector3

@export var x: int = 0:
    set(val):
        x = val
        if Engine.is_editor_hint():
            return
        if self.x_setter_callback != null:
            self.x_setter_callback.call()
        if self.universal_setter_callback != null:
            self.universal_setter_callback.call()

@export var y: int = 0:
    set(val):
        y = val
        if Engine.is_editor_hint():
            return
        if self.y_setter_callback != null:
            self.y_setter_callback.call()
        if self.universal_setter_callback != null:
            self.universal_setter_callback.call()


@export var z: int = 0:
    set(val):
        z = val
        if Engine.is_editor_hint():
            return
        if self.z_setter_callback != null:
            self.z_setter_callback.call()
        if self.universal_setter_callback != null:
            self.universal_setter_callback.call()

var x_setter_callback #: Callable 
var y_setter_callback
var z_setter_callback
var universal_setter_callback 

func _init(x_inc: int = 0, y_inc: int = 0, z_inc: int = 0):
    self.x = x_inc
    self.y = y_inc
    self.z = z_inc

# also copied from SGPhysics2D, which copied from wikipedia. theft is an art
# https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_.28base_2.29
# ALSO also; woulda really like to prototype this onto int but OH WELL
func sqrt_64(num: int) -> int:
    if num == 0:
        return 0

    var neg: bool = num < 0
    if neg:
        num = -num

    var res: int = 0
    var bit: int = 1 << 62

    # start at highest power of four thats less than or equal to num
    while bit > num:
        bit >>= 2

    while bit != 0:
        if num >= res + bit:
            num -= res + bit
            res = (res >> 1) + bit
        else:
            res >>= 1
        bit >>= 2

    return -res if neg else res


func length() -> int:
    var length_sqrd := self.length_squared()

    if length_sqrd == 0:
        return 0

    var lgth = sqrt_64(length_sqrd)
    if lgth == 0:
        return 1

    return lgth

func length_squared() -> int:
    var ret := (self.x * self.x) + (self.y * self.y) + (self.z * self.z) ## <<--- WRITE MULTIPLICATION AND DIVISION METHODS YOU FUCKHEAD
                                                                        #           THIS WONT WORK LIKE THIS <IDIOT>
    # squaring a fixed point number smaller than 15 will be 0
    # which means ret can be 0
    if (ret == 0) && (self.x != 0 || self.y != 0 || self.z != 0):
        return 1 # gotta return something
    return ret

static func from_vec3(val: Vector3) -> FixedVector3:
    var ret_vec = FixedVector3.new()

    ret_vec.x = int(val.x * 65536)
    ret_vec.y = int(val.y * 65536)
    ret_vec.z = int(val.z * 65536)

    return ret_vec

static func to_vec3(val: FixedVector3) -> Vector3:
    var ret_vec = Vector3()

    ret_vec.x = float(val.x / 65536.0)
    ret_vec.y = float(val.y / 65536.0)
    ret_vec.z = float(val.z / 65536.0)

    return ret_vec

static func add(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
    var ret_vec = FixedVector3.new()

    ret_vec.x = vec1.x + vec2.x
    ret_vec.y = vec1.y + vec2.y
    ret_vec.z = vec1.z + vec2.z

    return ret_vec

func distance_to(vec2: FixedVector3) -> FixedVector3:
    var ret := FixedVector3.new()
    ret.x = vec2.x - self.x
    ret.y = vec2.y - self.y
    ret.z = vec2.z - self.z
    ret.normalize()
    return ret

# based on snopek games' SGPysics2D implementation, translated into 3d
func normalize():
    var x_abs: int = abs(self.x)
    var y_abs: int = abs(self.y)
    var z_abs: int = abs(self.z)

    # values under 2048 give imprecise results.
    # we only care about direction, so we can increase the vector's magnitude as a workaround
    if ((self.x != 0 && x_abs < 2048) || (self.y != 0 && y_abs < 2048) || (self.z != 0 && z_abs < 2048)):

        # need to watch out for values that may overflow 64 bit integers
        # 1482910 = sqrt(MAX_SIGNED_64BIT_NUMBER) / 2048

        if (x_abs >= 1482910):
            self.x = 65536 if self.x > 0 else -65536
            self.y = 0
            self.z = 0
        
        elif (y_abs >= 1482910):
            self.x = 0
            self.y = 65536 if self.x > 0 else -65536
            self.z = 0

        elif (z_abs >= 1482910):
            self.x = 0
            self.y = 0
            self.z = 65536 if self.x > 0 else -65536

        else:
            # multiply xyz by 2048
            var x_big = self.x << 11 # bit shifting is much faster than regular multiplication
            var y_big = self.y << 11
            var z_big = self.z << 11

            var lgth = FixedVector3.new(
                    x_big, 
                    y_big, 
                    z_big
                ).length()

            if lgth != 0:
                self.x = x_big / lgth

    else:
        pass