const { readFileSync } = require( 'fs' )
const { fromPng } = require( '@rgba-image/png' )

const data = [
  {
    name: 'PlayerSprite',
    src: './data/player.png'
  },
  {
    name: 'SwordSprite',
    src: './data/sword.png'
  },
  {
    name: 'ShieldSprite',
    src: './data/shield.png'
  }
]

data.forEach(
  ( { name, src } ) => {
    const image = fromPng( readFileSync( src ) )

    const { width, height } = image

    if ( width !== 8 )
      throw Error( 'Expected 8px wide sprite' )

    const rows = []

    for ( let y = 0; y < height; y++ ) {
      let row = ''

      for ( let x = 0; x < width; x++ ) {
        const index = y * width + x
        const srcIndex = index * 4

        const r = image.data[ srcIndex ]

        row += r ? '1' : '0'
      }

      rows.unshift( row )
    }

    console.log( `${ name }:` )

    rows.forEach( row => {
      console.log( `  .byte #%${ row }` )
    } )

    console.log()
  }
)