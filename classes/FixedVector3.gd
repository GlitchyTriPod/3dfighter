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

static func sub(vec1: FixedVector3, vec2: FixedVector3) -> FixedVector3:
    var ret_vec = FixedVector3.new()

    ret_vec.x = vec1.x - vec2.x
    ret_vec.y = vec1.y - vec2.y
    ret_vec.z = vec1.z - vec2.z

    return ret_vec

static func mul(vec: FixedVector3, num: int) -> FixedVector3:
    var ret_vec = FixedVector3.new()

    ret_vec.x = FixedInt.mul(vec.x, num)
    ret_vec.y = FixedInt.mul(vec.y, num)
    ret_vec.z = FixedInt.mul(vec.z, num)

    return ret_vec

static func div(vec: FixedVector3, num: int) -> FixedVector3:
    var ret_vec = FixedVector3.new()

    ret_vec.x = FixedInt.div(vec.x, num)
    ret_vec.y = FixedInt.div(vec.y, num)
    ret_vec.z = FixedInt.div(vec.z, num)

    return ret_vec

func length() -> int:
    var length_sqrd := self.length_squared()

    if length_sqrd == 0:
        return 0

    var lgth = FixedInt.sqrt_64(length_sqrd)
    if lgth == 0:
        return 1

    return lgth

func length_squared() -> int:
    var ret := FixedInt.mul(self.x, self.x) \
        + FixedInt.mul(self.y, self.y) \
        + FixedInt.mul(self.z, self.z)
                                              
    # squaring a fixed point number smaller than 15 will be 0
    # which means ret can be 0
    if (ret == 0) && (self.x != 0 || self.y != 0 || self.z != 0):
        return 1 # gotta return something
    return ret

func distance_to(vec: FixedVector3) -> int:
    return FixedVector3.sub(vec, self).length()

func distance_squared_to(vec: FixedVector3) -> int:
    return FixedVector3.sub(vec, self).length_squared()

func direction_to(vec2: FixedVector3) -> FixedVector3:
    var ret := FixedVector3.new()
    ret.x = vec2.x - self.x
    ret.y = vec2.y - self.y
    ret.z = vec2.z - self.z
    ret.normalize()
    return ret

func angle(axis: Vector3) -> int:
    match axis:
        Vector3.UP, Vector3.DOWN:
            return FixedInt.atan2(self.z, self.x)
        Vector3.LEFT, Vector3.RIGHT:
            return FixedInt.atan2(self.y, self.z)
        Vector3.FORWARD, Vector3.BACK:
            return FixedInt.atan2(self.y, self.x)
    return 0

func rotated(axis: Vector3, p_rotation: int) -> FixedVector3:
    var v = FixedVector3.new()
    v.rotate(axis, self.angle(axis) + p_rotation)
    v = FixedVector3.mul(v, v.length())
    return v

func rotate(axis: Vector3, ang: int) -> FixedVector3:
    match axis:
        Vector3.UP, Vector3.DOWN:
            # return FixedInt.atan2(self.x, self.z)
            self.x = FixedInt.cos(ang)
            self.z = FixedInt.sin(ang)
        Vector3.LEFT, Vector3.RIGHT:
            # return FixedInt.atan2(self.y, self.z)
            self.y = FixedInt.cos(ang)
            self.z = FixedInt.sin(ang)
        Vector3.FORWARD, Vector3.BACK:
            # return FixedInt.atan2(self.x, self.y)
            self.x = FixedInt.cos(ang)
            self.y = FixedInt.sin(ang)
    return self

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
            var x_big: int = self.x << 11 # bit shifting is much faster than regular multiplication
            var y_big: int = self.y << 11
            var z_big: int = self.z << 11

            var lgth := FixedVector3.new(
                    x_big, 
                    y_big, 
                    z_big
                ).length()

            if lgth != 0:
                self.x = FixedInt.div(x_big, lgth)
                self.y = FixedInt.div(y_big, lgth)
                self.z = FixedInt.div(z_big, lgth)

    else:
        var lgth = self.length()
        if lgth != 0:
            self.x = FixedInt.div(self.x, lgth)
            self.y = FixedInt.div(self.y, lgth)
            self.z = FixedInt.div(self.z, lgth)