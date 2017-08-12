#include "aschar_aux.as"
#include "situationawareness.as"
#include "interpdirection.as"

Situation situation;
int target_id = -1;

float startle_time;

bool has_jump_target = false;
vec3 jump_target_vel;

float awake_time = 0.0f;
const float AWAKE_NOTICE_THRESHOLD = 1.0f;

float enemy_seen = 0.0f;

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target_id = -1;
int old_waypoint_target_id = -1;
const float _throw_counter_probability = 0.2f;
bool will_throw_counter;
int ground_punish_decision = -1;

float notice_target_aggression_delay = 0.0f;
int notice_target_aggression_id = 0.0f;

float target_attack_range = 0.0f;
float strafe_vel = 0.0f;
const float _block_reflex_delay_min = 0.1f;
const float _block_reflex_delay_max = 0.2f;
float block_delay;
bool going_to_block = false;
float dodge_delay;
bool going_to_dodge = false;
float roll_after_ragdoll_delay;
bool throw_after_active_block;
bool allow_active_block = true;
bool always_unaware = false;
bool always_active_block = false;

bool combat_allowed = true;
bool chase_allowed = false;

float body_bob_freq = 0.0f;
float body_bob_time_offset;

class InvestigatePoint {
    vec3 pos;
    float seen_time;
};
array<InvestigatePoint> investigate_points;

const float kGetWeaponDelay = 0.4f;
float get_weapon_delay = kGetWeaponDelay;

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still};
AIGoal goal = _patrol;

enum AISubGoal {_unknown = -1, _punish_fall, _provoke_attack, _avoid_jump_kick, _wait_and_attack, _rush_and_attack, _defend, _surround_target, _escape_surround,
    _investigate_slow, _investigate_urgent, _investigate_body, _investigate_around};
AISubGoal sub_goal = _wait_and_attack;

AIGoal old_goal;
AISubGoal old_sub_goal;

int investigate_target_id = -1;
vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int chase_target_id = -1;
int weapon_target_id = -1;

float investigate_body_time;
float patrol_wait_until = 0.0f;

enum PathFindType {_pft_nav_mesh, _pft_climb, _pft_drop, _pft_jump};
PathFindType path_find_type = _pft_nav_mesh;
vec3 path_find_point;
float path_find_give_up_time;

enum ClimbStage {_nothing, _jump, _wallrun, _grab, _climb_up};
ClimbStage trying_to_climb = _nothing;
vec3 climb_dir;

int num_ribbons = 1;
int fire_object_id = -1;
bool on_fire = false;
float flame_effect = 0.0f;

int shadow_id = -1;
int lf_shadow_id = -1;
int rf_shadow_id = -1;

// Parameter values
float p_aggression;
float p_ground_aggression;
float p_damage_multiplier;
float p_block_skill;
float p_block_followup;
float p_attack_speed_mult;
float p_speed_mult;
float p_attack_damage_mult;
float p_attack_knockback_mult;
float p_fat;
float p_muscle;
float p_ear_size;
int p_lives;
int lives;

const float _base_run_speed = 8.0f; // used to calculate movement and jump velocities, change this instead of max_speed
const float _base_true_max_speed = 12.0f; // speed can never exceed this amount
float run_speed = _base_run_speed;
float true_max_speed = _base_true_max_speed;
float max_speed = run_speed; // this is recalculated constantly because actual max speed is affected by slopes

int tether_id = -1;

float breath_amount = 0.0f;
float breath_time = 0.0f;
float breath_speed = 0.9f;
array<float> resting_mouth_pose;
array<float> target_resting_mouth_pose;
float resting_mouth_pose_time = 0.0f;

float old_time = 0.0f;

vec3 ground_normal(0,1,0);
vec3 flip_modifier_axis;
float flip_modifier_rotation;
vec3 tilt_modifier;
const float collision_radius = 1.0f; // affects the size of a sphere collider used for leg collisions
enum IdleType{_stand, _active, _combat};
IdleType idle_type = _active;

bool idle_stance = false;
float idle_stance_amount = 0.0f;

// the main timer of the script, used whenever anything has to know how much time has passed since something else happened.
float time = 0;

vec3 head_look;
vec3 torso_look;

string[] legs = { "left_leg", "right_leg" };
string[] arms = { "leftarm", "rightarm" };

bool on_ground = false;
string dialogue_anim = "Data/Animations/r_sweep.anm";
int knocked_out = _awake;

// States are used to differentiate between various widely different situations
const int _movement_state = 0; // character is moving on the ground
const int _ground_state = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2; // character is performing an attack
const int _hit_reaction_state = 3; // character was hit or dealt damage to and has to react to it in some manner
const int _ragdoll_state = 4; // character is falling in ragdoll mode
int state = _movement_state;

vec3 last_col_pos;
float duck_amount = 0.5f;
const float _bumper_size = 2.5f;
const float _ground_normal_y_threshold = 0.5f;

bool balancing = false;
vec3 balance_pos;

bool show_debug = false;
bool dialogue_control = false;
bool static_char = false;
int invisible_when_stationary = 0;
int species = 0;
float threat_amount = 0.0f;
float target_threat_amount = 0.0f;
float threat_vel = 0.0f;
int primary_weapon_slot = 0;
int secondary_weapon_slot = 1;
array<int> weapon_slots = {-1, -1};
int knife_layer_id = -1;
int throw_knife_layer_id = -1;
float land_magnitude = 0.0f;
float character_scale = 1.0f;
AttackScriptGetter attack_attacker;
float block_stunned = 1.0f;
int block_stunned_by_id = -1;


array<BoneTransform> skeleton_bind_transforms;
array<BoneTransform> inv_skeleton_bind_transforms;
array<int> ik_chain_elements;
enum IKLabel {kLeftArmIK, kRightArmIK, kLeftLegIK, kRightLegIK,
              kHeadIK, kLeftEarIK, kRightEarIK, kTorsoIK,
              kTailIK, kNumIK };
array<int> ik_chain_start_index;
array<int> ik_chain_length;
array<float> ik_chain_bone_lengths;
array<int> bone_children;
array<int> bone_children_index;
array<vec3> convex_hull_points;
array<int> convex_hull_points_index;

// Key transform enums
const int kHeadKey = 0;
const int kLeftArmKey = 1;
const int kRightArmKey = 2;
const int kLeftLegKey = 3;
const int kRightLegKey = 4;
const int kChestKey = 5;
const int kHipKey = 6;
const int kNumKeys = 7;

array<float> key_masses;
array<int> root_bone;

array<int> flash_obj_ids;

float last_changed_com = 0.0f;
vec3 com_offset;
vec3 com_offset_vel;
vec3 target_com_offset;

array<int> roll_check_bones;
array<BoneTransform> key_transforms;
array<float> target_leg_length;

vec3 push_velocity;

array<vec3> temp_old_ear_points;
array<vec3> old_ear_points;
array<vec3> ear_points;

array<float> target_ear_rotation;
array<float> ear_rotation;
array<float> ear_rotation_time;

int skip_ear_physics_counter = 0;

array<vec3> temp_old_tail_points;
array<vec3> old_tail_points;
array<vec3> tail_points;
array<vec3> tail_correction;
array<float> tail_section_length;

// Verlet integration for arm physics
array<vec3> temp_old_arm_points;
array<vec3> old_arm_points;
array<vec3> arm_points;
enum ChainPointLabels {kHandPoint, kWristPoint, kElbowPoint, kShoulderPoint, kCollarTipPoint, kCollarPoint, kNumArmPoints};

vec3 old_com;
vec3 old_com_vel;
vec3 old_hip_offset;
array<float> old_foot_offset;
array<quaternion> old_foot_rotate;

vec3 old_head_facing;
vec2 old_angle;
vec2 head_angle;
vec2 target_head_angle;
vec2 head_angle_vel;
vec2 head_angle_accel;
float old_head_angle;

vec3 old_chest_facing;
vec2 old_chest_angle_vec;
vec2 chest_angle;
vec2 target_chest_angle;
vec2 chest_angle_vel;
float old_chest_angle;
float ragdoll_fade_speed = 1000.0f;
float preserve_angle_strength = 0.0f;

quaternion total_body_rotation;

array<vec3> temp_old_weap_points;
array<vec3> old_weap_points;
array<vec3> weap_points;

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);
    time += ts.step();
    ApplyPhysics(ts);
    HandleCollisions(ts);
    UpdateJumping();
    UpdateFacing(ts);
}
float wiggle_wait = 0.0f;
float wave = 1.0f;

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
    float distance_threshold = character_scale;
    vec3 this_com = this_mo.rigged_object().skeleton().GetCenterOfMass();
    vec3 other_com = other.rigged_object().skeleton().GetCenterOfMass();
    this_com.y = this_mo.position.y;
    other_com.y = other.position.y;
    if(distance(this_com, other_com) < distance_threshold){
        vec3 dir = other_com - this_com;
        float dist = length(dir);
        dir /= dist;
        dir *= distance_threshold - dist;
        vec3 other_push = dir * 0.5f / (time_step) * 0.15f;
        this_mo.velocity += other_push;
        other.Execute("
        if(!static_char){
            push_velocity += vec3("+other_push.x+","+other_push.y+","+other_push.z+");
            MindReceiveMessage(\"collided "+this_mo.GetID()+"\");
        }");
    }
}

float jump_wait = 0.0f;
float long_offset = 3.14f;
float long_magnitude = 0.0f;
float wide_offset = 3.14f;
void UpdateJumping(){
    bool allow_jumping = true;
    if(on_ground && allow_jumping){
        jump_wait -= time_step;
        if(jump_wait < 0.0f){
            jump_wait = RangedRandomFloat(0.25f, 0.50f);
            float jump_mult = 5.0f;
            vec3 jump_vel;
            jump_vel.y = RangedRandomFloat(1.0f, 2.0f);
            jump_vel.x = RangedRandomFloat(-1.0f, 1.0f);
            jump_vel.z = RangedRandomFloat(-1.0f, 1.0f);
            this_mo.velocity += jump_vel * jump_mult;
            long_magnitude = length(this_mo.velocity) * 0.05f;
            long_offset = 0.0f;
        }
    }
    if(long_offset < 3.14f){
        long_offset += time_step * 50.0f;
        this_mo.rigged_object().SetMorphTargetWeight("long",pow(sin(long_offset), 2.0f), long_magnitude);
    }else{
        this_mo.rigged_object().SetMorphTargetWeight("long",0.0f, 1.0f);
    }
    float damping_time = 20.0f;
    if(wide_offset < damping_time){
        wide_offset += time_step * 40.0f;
        float weight = (damping_time - wide_offset) * 0.02f * pow(sin(wide_offset), 2.0f);
        this_mo.rigged_object().SetMorphTargetWeight("wide", weight, min(1.0f, land_magnitude));
        this_mo.rigged_object().SetMorphTargetWeight("deep", weight, min(1.0f, land_magnitude));
    }else{
        this_mo.rigged_object().SetMorphTargetWeight("wide",0.0f, 1.0f);
        this_mo.rigged_object().SetMorphTargetWeight("deep",0.0f, 1.0f);
    }
}

void UpdateFacing(const Timestep &in ts){
    vec3 flat_vel = vec3(this_mo.velocity.x, 0.0f, this_mo.velocity.z);
    this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(), flat_vel, 1.0 - pow(0.95f, ts.frames())));
}

void FinalAttachedItemUpdate(int num_frames) {
}

void HandleAnimationEvent(string event, vec3 world_pos){

}
void Reset() {
    this_mo.rigged_object().anim_client().RemoveAllLayers();
    this_mo.DetachAllItems();
    this_mo.rigged_object().CleanBlood();
    this_mo.rigged_object().SetWet(0.0);
    this_mo.rigged_object().Extinguish();
    ClearTemporaryDecals();
    this_mo.rigged_object().ClearBoneConstraints();
}

bool Init(string character_path) {
    this_mo.char_path = character_path;
    bool success = character_getter.Load(this_mo.char_path);
    if(success){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        this_mo.SetAnimation("Data/Animations/default.anm", 20.0f, 0);
    }
    return success;

    /*character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    this_mo.SetAnimation("Data/Animations/default.anm", 20.0f, 0);*/
}

void PostReset() {
}

void ApplyPhysics(const Timestep &in ts) {
    if(!on_ground){
        this_mo.velocity += physics.gravity_vector * ts.step();
    }
    bool feet_moving = false;
    float _walk_accel = 35.0f; // how fast characters accelerate when moving
    if(on_ground){
        this_mo.velocity *= pow(0.95f,ts.frames());
    }
}

void HandleCollisions(const Timestep &in ts) {
    vec3 scale;
    float size;
    GetCollisionSphere(scale, size);
    if(show_debug){
        DebugDrawWireSphere(this_mo.position, size, vec3(1.0f,1.0f,1.0f), _delete_on_update);
    }
    if(on_ground){
        HandleGroundCollisions(ts);
    } else {
        HandleAirCollisions(ts);
    }
}

void HandleGroundCollisions(const Timestep &in ts) {
    vec3 old_vel = this_mo.velocity;
    // Check if character has room to stand up
    float old_duck_amount = duck_amount;
    vec3 test_bumper_collision_response(0.0f, -10.0f, 0.0f);
    vec3 old_pos = this_mo.position;
    vec3 bumper_collision_response = HandleBumperCollision();
    bool in_air = HandleStandingCollision();
    if(in_air){
        on_ground = false;
    }
}

bool HandleStandingCollision() {
    vec3 lower_pos = this_mo.position - vec3(0.0f, 0.05f, 0.0f);
    vec3 scale;
    float size;
    GetCollisionSphere(scale, size);
    col.GetSweptSphereCollision(this_mo.position, lower_pos, size);
    if(show_debug){
        DebugDrawWireSphere(this_mo.position, size, vec3(0.0f,0.0f,1.0f), _delete_on_update);
        DebugDrawWireSphere(lower_pos, size, vec3(0.0f,0.0f,1.0f), _delete_on_update);
    }
    return (sphere_col.position == lower_pos);
}

void HandleAirCollisions(const Timestep &in ts) {
    vec3 initial_vel = this_mo.velocity;
    vec3 offset = this_mo.position - last_col_pos;
    this_mo.position = last_col_pos;
    bool landing = false;
    vec3 old_vel = this_mo.velocity;
    for(int i=0; i<ts.frames(); ++i){                                        // Divide movement into multiple pieces to help prevent surface penetration
        if(on_ground){
            break;
        }
        this_mo.position += offset/ts.frames();
        vec3 scale;
        float size;
        GetCollisionSphere(scale, size);
        col.GetSlidingScaledSphereCollision(this_mo.position, size, scale);
        if(show_debug){
            DebugDrawWireScaledSphere(this_mo.position, size, scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
        }

        vec3 closest_point;
        float closest_dist = -1.0f;
        for(int j=0; j<sphere_col.NumContacts(); j++){
            const CollisionPoint contact = sphere_col.GetContact(j);
            land_magnitude = length(this_mo.velocity);
            float bounciness = 0.5f;
            float max_bounce_vel = 150.0f;
            if(contact.normal.y > _ground_normal_y_threshold ||
                (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f) ||
                (contact.custom_normal.y >= 1.0 && contact.custom_normal.y < 4.0))
                {  // If collision with a surface that can be walked on, then land
                    landing = true;
                    PlaySoundGroup("Data/Sounds/weapon_foley/impact/weapon_drop_light_dirt.xml", this_mo.position, 1.0f);
                    //The charater is pushed back when colliding with the ground.
                    /*this_mo.position = contact.position + vec3(0.0f, character_scale, 0.0f);*/
                    this_mo.velocity += contact.normal * length(this_mo.velocity) * bounciness;
                }else{
                    //A wall
                    /*this_mo.position = contact.position + (character_scale * contact.normal);*/
                    this_mo.velocity = contact.normal * length(this_mo.velocity);
                }
        }
    }
    if(landing){
        //Print("Land " + length(this_mo.velocity) + "\n");
        wide_offset = 0.0f;
        on_ground = true;
    }
}

void GetCollisionSphere(vec3 &out scale, float &out size){
    scale = vec3(1.0f);
    size = character_scale;
}

vec3 HandleBumperCollision(){
    vec3 scale;
    float size;
    GetCollisionSphere(scale, size);
    col.GetSlidingScaledSphereCollision(this_mo.position, size, scale);
    if(show_debug){
        DebugDrawWireScaledSphere(this_mo.position, size, scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    }
    this_mo.position = sphere_col.adjusted_position;
    return (sphere_col.adjusted_position - sphere_col.position);
}

int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    attack_attacker.Load(attack_path);
    if(type == "attackimpact"){
        PlaySoundGroup("Data/Sounds/hit/hit_block.xml", pos, _sound_priority_high);
        return HitByAttack(dir, pos, attacker_id, attack_damage_mult, attack_knockback_mult);
    }
    return 0;
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    this_mo.velocity += (attack_attacker.GetForce() * dir * attack_damage_mult * attack_knockback_mult) * 0.0004f * (2.1f - character_scale);
    return 0;
}

int AboutToBeHitByItem(int id){
    Print("About to be hit\n");
    return 1;
}

void HitByItem(string material, vec3 point, int id, int type) {
    // Get force of object movement
    ItemObject@ io = ReadItemID(id);
    vec3 lin_vel = io.GetLinearVelocity();
    vec3 force = (lin_vel - this_mo.velocity) * io.GetMass() * 0.25f;
    // Apply force to character velocity
    this_mo.velocity += force;
}

void ImpactSound(float magnitude, vec3 position) {
    this_mo.MaterialEvent("bodyfall", position);
}

void ResetLayers() {

}

void Dispose() {
}

void DisplayMatrixUpdate(){
}

void MovementObjectDeleted(int id){
}

bool queue_fix_discontinuity = false;
void FixDiscontinuity() {
    queue_fix_discontinuity = true;
}

void PreDrawCameraNoCull(float curr_game_time) {
    if(queue_fix_discontinuity){
        Update(1);
        this_mo.FixDiscontinuity();
        FinalAnimationMatrixUpdate(1);
        queue_fix_discontinuity = false;
    }
}

void FinalAnimationMatrixUpdate(int num_frames) {

    vec3 scale;
    float size;
    GetCollisionSphere(scale, size);

    RiggedObject@ rigged_object = this_mo.rigged_object();
    BoneTransform local_to_world;
    vec3 offset = this_mo.position;
    offset.y -= size;
    vec3 facing = this_mo.GetFacing();
    float cur_rotation = atan2(facing.x, facing.z);
    quaternion rotation(vec4(0,1,0,cur_rotation));
    local_to_world.rotation = rotation;
    local_to_world.origin = offset;
    rigged_object.TransformAllFrameMats(local_to_world);
}

int IsUnaware() {
    return 0;
}

void ResetMind() {

}

int IsIdle() {
    if(goal == _patrol){
        return 1;
    } else {
        return 0;
    }
}

int IsAggressive() {
    return 0;
}

void Notice(int character_id){

}

void ResetSecondaryAnimation() {
    ear_rotation.resize(0);
    tail_points.resize(0);
    arm_points.resize(0);
    ear_points.resize(0);
    old_foot_offset.resize(0);
    old_foot_rotate.resize(0);
    weap_points.resize(0);
    old_hip_offset = vec3(0.0f);
}

float move_delay = 0.0f;
float repulsor_delay = 0.0f;

void MindReceiveMessage(string msg){
}
void ReceiveMessage(string msg){
}

bool IsAware(){
    return hostile;
}

int NeedsAnimFrames(){
    return 0;
}

int IsPassive() {
    return 0;
}

int IsOnLedge(){
    return 0;
}

int IsDodging(){
    return 0;
}

int IsAggro() {
    return 1;
}

void SetParameters() {
    params.AddIntCheckbox("Static",false);
    static_char = (params.GetInt("Static") != 0);

    string team_str;
    character_getter.GetTeamString(team_str);
    params.AddString("Teams",team_str);

    params.AddFloatSlider("Character Scale",0.5,"min:0.25,max:2.0,step:0.02,text_mult:100");
    character_scale = params.GetFloat("Character Scale");
    if(character_scale != this_mo.rigged_object().GetRelativeCharScale()){
        this_mo.RecreateRiggedObject(this_mo.char_path);
        ResetSecondaryAnimation();
        this_mo.SetAnimation("Data/Animations/default.anm", 20.0f, 0);
    }
}
