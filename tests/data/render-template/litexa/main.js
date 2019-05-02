const getListItems = function(template){
  let list = [];
  switch (template) {
    case 1:
      list = [
        {token: '1', primaryText: '1st Primary Text', secondaryText: '1st Secondary Text', tertiaryText: '1st Tertiary Text', image: 'brie.png'},
        {token: '2', primaryText: '2nd Primary Text', secondaryText: '2nd Secondary Text', tertiaryText: '2nd Tertiary Text', image: 'gorgonzola.png'},
        {token: '3', primaryText: '3rd Primary Text', secondaryText: '3rd Secondary Text', tertiaryText: '3rd Tertiary Text', image: 'gruyere.png'},
        {token: '4', primaryText: '4th Primary Text', secondaryText: '4th Secondary Text', tertiaryText: '4th Tertiary Text', image: 'brie.png'},
        {token: '5', primaryText: '5th Primary Text', secondaryText: '5th Secondary Text', tertiaryText: '5th Tertiary Text', image: 'gorgonzola.png'},
        {token: '6', primaryText: '6th Primary Text', secondaryText: '6th Secondary Text', tertiaryText: '6th Tertiary Text', image: 'gruyere.png'}
      ];
      break;

    case 2:
      list = [
        {token: '1', primaryText: '1st Primary Text', secondaryText: '1st Secondary Text', image: 'brie.png'},
        {token: '2', primaryText: '2nd Primary Text', secondaryText: '2nd Secondary Text', image: 'gorgonzola.png'},
        {token: '3', primaryText: '3rd Primary Text', secondaryText: '3rd Secondary Text', image: 'gruyere.png'},
        {token: '4', primaryText: '4th Primary Text', secondaryText: '4th Secondary Text', image: 'brie.png'},
        {token: '5', primaryText: '5th Primary Text', secondaryText: '5th Secondary Text', image: 'gorgonzola.png'},
        {token: '6', primaryText: '6th Primary Text', secondaryText: '6th Secondary Text', image: 'gruyere.png'},
      ];
      break;

    default:
      console.log(`getListItems: unknown template '${template}'`);
      break;
  }
  return list;
}

const listOneItems = getListItems(1);
const listTwoItems = getListItems(2);
