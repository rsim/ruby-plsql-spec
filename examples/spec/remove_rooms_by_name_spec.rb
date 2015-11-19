require 'remove_rooms_by_name'

describe "Remove rooms by name" do
  before(:all) do
    plsql.rooms.insert_values(
      [:room_key, :name],
      [1, 'Dining Room'],
      [2, 'Living Room'],
      [3, 'Office'],
      [4, 'Bathroom'],
      [5, 'Bedroom']
    )
    plsql.room_contents.insert_values(
      [:contents_key, :room_key, :name],
      [1, 1, 'Table'],
      [2, 1, 'Hutch'],
      [3, 1, 'Chair'],
      [4, 2, 'Sofa'],
      [5, 2, 'Lamp'],
      [6, 3, 'Desk'],
      [7, 3, 'Chair'],
      [8, 3, 'Computer'],
      [9, 3, 'Whiteboard']
    )
  end

  it "should remove a room without furniture" do
    rooms_without_b = plsql.rooms.all("WHERE name NOT LIKE 'B%'")
    plsql.remove_rooms_by_name('B%')
    expect(plsql.rooms.all).to eq rooms_without_b
  end

  it "should not remove a room with furniture" do
    expect {
      expect {
        plsql.remove_rooms_by_name('Living Room')
      }.to raise_error(/ORA-02292/)
    }.not_to change { plsql.rooms.all }
  end

  it "should raise exception when NULL value passed" do
    expect {
      expect {
        plsql.remove_rooms_by_name(NULL)
      }.to raise_error(/program error/)
    }.not_to change { plsql.rooms.all }
  end

end
