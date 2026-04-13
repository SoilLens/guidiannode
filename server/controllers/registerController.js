const supabase = require('../services/supabaseClient');

const registerUser = async (req, res) => {
  try {
    const {
      full_name,
      phone_number,
      quarter,
      location_permission,
      latitude,
      longitude,
      emergency_contact
    } = req.body;

    // 1. Verify required fields exist
    if (!full_name || !phone_number || !quarter) {
      return res.status(400).json({
        success: false,
        message: 'Missing required full_name, phone_number, or quarter',
      });
    }

    if (!emergency_contact ||
        !emergency_contact.contact_name ||
        !emergency_contact.phone_number ||
        !emergency_contact.relationship) {
      return res.status(400).json({
        success: false,
        message: 'Emergency contact is required with contact_name, phone_number, and relationship',
      });
    }

    // 2. Extract specific ID from Supabase Auth middleware
    const userId = req.user.id;

    // Determine the phone number to trust (From Auth session instead of body payload)
    // Supabase auth user object contains the phone if they signed in via phone OTP
    const verifiedPhone = req.user.phone || phone_number;

    // 3. Prepare Location Data based on permission
    const finalLatitude = location_permission ? latitude : null;
    const finalLongitude = location_permission ? longitude : null;

    // 4. Insert into 'users' table
    const { error: userInsertError } = await supabase
      .from('users')
      .insert({
        id: userId,
        full_name,
        phone_number: verifiedPhone,
        quarter,
        location_permission: location_permission || false,
        latitude: finalLatitude,
        longitude: finalLongitude,
        created_at: new Date().toISOString()
      });

    if (userInsertError) {
      // If error code is 23505 (Unique violation), user already exists
      if (userInsertError.code === '23505') {
          return res.status(409).json({
              success: false,
              message: 'User profile already exists',
          });
      }
      throw userInsertError;
    }

    // 5. Insert into 'emergency_contacts' table
    const { error: contactInsertError } = await supabase
      .from('emergency_contacts')
      .insert({
        user_id: userId,
        contact_name: emergency_contact.contact_name,
        phone_number: emergency_contact.phone_number,
        relationship: emergency_contact.relationship,
        created_at: new Date().toISOString()
      });

    if (contactInsertError) {
      // Depending on severity, we could roll back or just report warning.
      // Assuming a strict failure requirement if contact fails:
      throw contactInsertError;
    }

    // 6. Success
    return res.status(201).json({
      success: true,
      message: 'User registration completed successfully'
    });

  } catch (error) {
    console.error('Registration Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during registration',
      error: error.message
    });
  }
};

module.exports = { registerUser };
