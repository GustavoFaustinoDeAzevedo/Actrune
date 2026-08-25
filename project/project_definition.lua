local project_definition = {
  resources = {
    physical_material = {
      ball = {
        properties = {
          density = 1,
          restitution = 0.6,
          friction = 0.3
        }
      },

      floor = {
        properties = {
          restitution = 0.2,
          friction = 0.8
        }
      }
    }
  },

  entities = {
    {
      id = "bounce_ball",

      transform = {
        x = 280,
        y = 200
      },

      shapes = {
        physics = {
          type = "circle",
          radius = 10,
          material = "ball"
        }
      },

      components = {
        rigid_body = {
          type = "rigid_body",
          body_type = "dynamic",
          shapes = { "physics" }
        }
      }
    },

    {
      id = "floor",

      transform = {
        x = 320,
        y = 480
      },

      shapes = {
        physics = {
          type = "polygon",
          material = "floor",

          points = {
            { x = -250, y = -20 },
            { x = -80,  y = -20 },
            { x = -40,  y = -70 },
            { x = 0,    y = -20 },
            { x = 250,  y = -20 },
            { x = 250,  y = 20 },
            { x = -250, y = 20 }
          }
        }
      },

      components = {
        rigid_body = {
          type = "rigid_body",
          body_type = "static",
          shapes = { "physics" }
        }
      }
    }
  }
}

return project_definition
