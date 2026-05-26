'use strict';
const { Model, Sequelize } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_properties extends Model {

    static associate(models) {
      tbl_properties.belongsTo(models.tbl_property_detail, { foreignKey: 'property_id', targetKey: "propDetail_propId", as: "propDetails" });
      tbl_properties.belongsTo(models.tbl_user, { foreignKey: 'property_host_id', targetKey: "user_id", as: "HostDetails" });
      tbl_properties.hasMany(models.tbl_negotiation_offers, {
        foreignKey: 'property_id',
        as: 'negotiationOffers'
      });

      // 🟡 Add association to negotiation/chat messages
      tbl_properties.hasMany(models.tbl_nagotiate_messages, {
        foreignKey: 'property_id',
        as: 'chatMessages'
      });

      // Add associations for junction tables
      tbl_properties.hasMany(models.tbl_prop_to_cat, { foreignKey: 'pt_cat_prop_id', as: 'propertyCategories' });
      tbl_properties.hasMany(models.tbl_prop_to_amenities, { foreignKey: 'pa_prop_id', as: 'propertyAmenities' });
      tbl_properties.hasMany(models.tbl_prop_to_tag, { foreignKey: 'pt_tag_prop_id', as: 'propertyTags' });


    };

    static async getPropertiesBylangLat(userLat, userLng, kmRadius) {
      try {
        const data = await tbl_properties.findAll({
          attributes: [
            "property_id",
            "property_longitude",
            "property_latitude",
            "property_price",
            [
              Sequelize.literal(`(
                  6371 * acos(
                    cos(radians(:userLat)) *
                    cos(radians(property_latitude)) *
                    cos(radians(property_longitude) - radians(:userLng)) +
                    sin(radians(:userLat)) *
                    sin(radians(property_latitude))
                  )
                )`),
              'distance'
            ]
          ],
          where: Sequelize.where(
            Sequelize.literal(`(
                6371 * acos(
                  cos(radians(:userLat)) *
                  cos(radians(property_latitude)) *
                  cos(radians(property_longitude) - radians(:userLng)) +
                  sin(radians(:userLat)) *
                  sin(radians(property_latitude))
                )
              )`),
            '<=',
            kmRadius
          ),
          replacements: { userLat, userLng }, // Parameterized values
          order: Sequelize.literal('distance ASC'), // Order by nearest first
        });
        return data;
      } catch (error) {
        return error;
      }
    };
    static async getSingleProperty(whereClause, attributes) {
      try {
        let att = attributes ?? { exclude: ["is_active", "is_deleted", "created_at", "updated_at"] };
        const data = await tbl_properties.findOne({
          raw: true,
          where: whereClause,
          attributes: att
        });
        return data;
      } catch (error) {
        return error;
      }
    };
    static async createProperty(payload) {
      try {
        const data = await tbl_properties.create(payload);
        return data.dataValues;
      } catch (error) {
        return error;
      }
    };
    static async updateProperty(payload, propId) {
      try {
        await tbl_properties.update(payload, { where: { property_id: propId } });
      } catch (error) {
        return error;
      }
    };
    static async updatePropertyByWhereClause(payload, whereClause) {
      try {
        await tbl_properties.update(payload, { where: whereClause });
      } catch (error) {
        return error;
      }
    }

  }
  tbl_properties.init({
    property_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    property_host_id: DataTypes.INTEGER(11),
    property_name: DataTypes.STRING(50),
    property_address: DataTypes.STRING(255),
    property_longitude: DataTypes.DECIMAL(11, 8),
    property_latitude: DataTypes.DECIMAL(10, 8),
    property_desc: DataTypes.TEXT({ length: "long" }),
    property_price: DataTypes.DECIMAL(10, 2),
    property_mini_price: DataTypes.DECIMAL(10, 2),
    property_city: DataTypes.STRING(50),
    property_zip: DataTypes.STRING(20),
    property_state: DataTypes.STRING(255),
    property_contry: DataTypes.STRING(20),
    property_contact: DataTypes.STRING(20),
    property_email: DataTypes.STRING(50),
    is_active: DataTypes.TINYINT(1),
    is_deleted: DataTypes.TINYINT(1),
    is_verify: DataTypes.TINYINT(1),
    is_luxury: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_properties',
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        fields: ['property_longitude', 'property_latitude'], // Indexing for faster geolocation queries
      }
    ]
  });
  tbl_properties.addHook('afterFind', (results) => {

    // Check if results is null or undefined
    if (!results) {
      return results; // No results, return as is
    }

    // Handle array of results
    if (Array.isArray(results)) {
      results.forEach((row) => {
        if (row.is_active !== undefined) {
          row.is_active = row.is_active === 1 ? true : false;
        }
        if (row.is_verify !== undefined) {
          row.is_verify =
            row.is_verify === 1
              ? true
              : row.is_verify === 2
                ? "Rejected"
                : row.is_verify === 3
                  ? false
                  : row.is_verify;
        }
        if (row['propDetails.propDetail_isPetFriendly'] !== undefined) {
          row['propDetails.propDetail_isPetFriendly'] =
            row['propDetails.propDetail_isPetFriendly'] === 1 ? true :
              row['propDetails.propDetail_isPetFriendly'] === 0 ? false : null;

          row['propDetails.propDetail_isSmoke'] =
            row['propDetails.propDetail_isSmoke'] === 1 ? true :
              row['propDetails.propDetail_isSmoke'] === 0 ? false : null;
        }
      });
    } else if (typeof results === 'object') {
      if (results.is_active !== undefined) {
        results.is_active = results.is_active === 1 ? true : false;
      }

      if (results['propDetails.propDetail_isPetFriendly'] !== undefined) {
        results['propDetails.propDetail_isPetFriendly'] =
          results['propDetails.propDetail_isPetFriendly'] === 1 ? true :
            results['propDetails.propDetail_isPetFriendly'] === 0 ? false : null;

        results['propDetails.propDetail_isSmoke'] =
          results['propDetails.propDetail_isSmoke'] === 1 ? true :
            results['propDetails.propDetail_isSmoke'] === 0 ? false : null;
      }
    }

    return results;
  });
  return tbl_properties;
};
