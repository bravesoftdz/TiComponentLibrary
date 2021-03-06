(******************************************************************************)
(*                              TiCustomTreeView                              *)
(*                 Model and renderer for tree view components                *)
(*                                                                            *)
(*                                                                            *)
(* Copyright (c) 2020                                       Ivan Semenkov     *)
(* https://github.com/isemenkov/ticomponentlibrary          ivan@semenkov.pro *)
(*                                                          Ukraine           *)
(******************************************************************************)
(*                                                                            *)
(* This source  is free software;  you can redistribute  it and/or modify  it *)
(* under the terms of the GNU General Public License as published by the Free *)
(* Software Foundation; either version 3 of the License.                      *)
(*                                                                            *)
(* This code is distributed in the  hope that it will  be useful, but WITHOUT *)
(* ANY  WARRANTY;  without even  the implied  warranty of MERCHANTABILITY  or *)
(* FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public License for *)
(* more details.                                                              *)
(*                                                                            *)
(* A copy  of the  GNU General Public License is available  on the World Wide *)
(* Web at <http://www.gnu.org/copyleft/gpl.html>. You  can also obtain  it by *)
(* writing to the Free Software Foundation, Inc., 51  Franklin Street - Fifth *)
(* Floor, Boston, MA 02110-1335, USA.                                         *)
(*                                                                            *)
(******************************************************************************)

unit customtreeview;

{$mode objfpc}{$H+}
{$IFOPT D+}
  {$DEFINE DEBUG}
{$ENDIF}

interface

uses
  Classes, SysUtils, CustomScrollingListControl;

type
  { Custom tree view model }
  generic TiCustomTreeViewModel<Item> = class (TInterfacedObject,
    IScrollingIScrollingListModel)

  end;

  { TiTreeViewItem }

  generic TiTreeViewItem<TItemData> = class
  public
    type
      PTreeViewItem = ^TTreeViewItem;
      TTreeViewItem = specialize TiTreeViewItem<TItemData>;
  protected
    FItemData : TItemData;
    FPrevElement : PTreeViewItem;
    FNextElement : PTreeViewItem;
    FChildrenElement : PTreeViewItem;
    FLastChildrenElement : PTreeViewItem;

    function GetValue : TItemData; {$IFNDEF DEBUG}inline;{$ENDIF}
    procedure SetValue (AItemData : TItemData); {$IFNDEF DEBUG}inline;{$ENDIF}
  public
    constructor Create (AItemData : TItemData);
    destructor Destroy; override;

    function PrevElement : PTreeViewItem; {$IFNDEF DEBUG}inline;{$ENDIF}
    function NextElement : PTreeViewItem; {$IFNDEF DEBUG}inline;{$ENDIF}
    function HasChildrens : Boolean; {$IFNDEF DEBUG}inline;{$ENDIF}
    function ChildrenElement : PTreeViewItem; {$IFNDEF DEBUG}inline;{$ENDIF}

    function AddChildren (AItemData : TItemData) : PTreeViewItem;

    property Value : TItemData read GetValue write SetValue;
  end;

  { TiTreeViewModel }

  generic TiTreeViewModel<TTreeItem> = class (TInterfacedObject,
    specialize IListModel<TTreeItem>)
  public
    type
      PTreeViewItem = ^TTreeViewItem;
      TTreeViewItem = specialize TiTreeViewItem<TTreeItem>;

      { TiTreeViewModelEnumerator }

      TiTreeViewModelEnumerator = class
      protected
        FTreeViewItem : PTreeViewItem;
        FCurrentItem : PTreeViewItem;

        function GetCurrent : TTreeViewItem;
      public
        constructor Create (ATreeViewItem : TTreeViewItem);
        function MoveNext : Boolean;
        property Current : TTreeViewItem read GetCurrent;
      end;
  protected
    FHeadElement : PTreeViewItem;
    FLastElement : PTreeViewItem;

  public
    constructor Create;
    destructor Destroy; override;

    function GetEnumerator : TiTreeViewModelEnumerator;

    function Empty : Boolean; {$IFNDEF DEBUG}inline;{$ENDIF}
    function AddElement (ATreeItem : TTreeItem) : PTreeViewItem;
  end;

  { Custom tree view renderer }
  generic TiCustomTreeViewRenderer<Item> = class (TInterfacedObject,
    IScrollingListRenderer)

  end;

implementation

{ TiTreeViewModel.TiTreeViewModelEnumerator }

function TiTreeViewModel.TiTreeViewModelEnumerator.GetCurrent: TTreeViewItem;
begin
  Result := FCurrentItem^;
  FCurrentItem := FCurrentItem^.NextElement;
end;

constructor TiTreeViewModel.TiTreeViewModelEnumerator.Create(
  ATreeViewItem: TTreeViewItem);
begin
  FTreeViewItem := ATreeViewItem;
  FCurrentItem := ATreeViewItem;
end;

function TiTreeViewModel.TiTreeViewModelEnumerator.MoveNext: Boolean;
begin
  Result := FCurrentItem <> nil;
end;

{ TiTreeViewModel }

constructor TiTreeViewModel.Create;
begin
  FHeadElement := nil;
  FLastElement := nil;
end;

destructor TiTreeViewModel.Destroy;
var
  Elem, Prev : PTreeViewItem;
begin
  Elem := FLastElement;
  while (Elem <> nil) do
  begin
    Prev := Elem^.PrevElement;
    FreeAndNil(Elem);
    Elem := Prev;
  end;

  inherited Destroy;
end;

function TiTreeViewModel.GetEnumerator: TiTreeViewModelEnumerator;
begin
  Result := TiTreeViewModelEnumerator.Create(FHeadElement^);
end;

function TiTreeViewModel.Empty: Boolean;
begin
  Result := FHeadElement = nil;
end;

function TiTreeViewModel.AddElement(ATreeItem: TTreeItem): PTreeViewItem;
var
  NewElement : PTreeViewItem;
begin
  if Empty then
  begin
    New(FHeadElement{%H-});
    FHeadElement^ := TTreeViewItem.Create(ATreeItem);
    FLastElement := FHeadElement;
    Result := FHeadElement;
    Exit;
  end;

  New(NewElement{%H-});
  NewElement^ := TTreeViewItem.Create(ATreeItem);
  NewElement^.FPrevElement := FLastElement;
  FLastElement^.FNextElement := NewElement;
  FLastElement := NewElement;
end;

{ TiTreeViewItem }

function TiTreeViewItem.HasChildrens: Boolean;
begin
  Result := FChildrenElement <> nil;
end;

function TiTreeViewItem.ChildrenElement: PTreeViewItem;
begin
  Result := FChildrenElement;
end;

function TiTreeViewItem.AddChildren(AItemData: TItemData): PTreeViewItem;
begin
  if not HasChildrens then
  begin
    New(FChildrenElement{%H-});
    FChildrenElement^ := TTreeViewItem.Create(AItemData);
    FLastChildrenElement := FChildrenElement;
    Result := FChildrenElement;
    Exit;
  end;

  New(FLastChildrenElement^.FNextElement{%H-});
  FLastChildrenElement^.FNextElement^ := TTreeViewItem.Create(AItemData);
  FLastChildrenElement^.FNextElement^.FPrevElement := FLastChildrenElement;
  FLastChildrenElement := FLastChildrenElement^.FNextElement;
end;

function TiTreeViewItem.PrevElement: PTreeViewItem;
begin
  Result := FPrevElement;
end;

function TiTreeViewItem.NextElement: PTreeViewItem;
begin
  Result := FNextElement;
end;

function TiTreeViewItem.GetValue: TItemData;
begin
  Result := FItemData;
end;

procedure TiTreeViewItem.SetValue(AItemData: TItemData);
begin
  FItemData := AItemData;
end;

constructor TiTreeViewItem.Create(AItemData: TItemData);
begin
  FItemData := AItemData;
  FPrevElement := nil;
  FNextElement := nil;
  FChildrenElement := nil;
  FLastChildrenElement := nil;
end;

destructor TiTreeViewItem.Destroy;
var
  Elem, Prev : PTreeViewItem;
begin
  Elem := FLastChildrenElement;
  while (Elem <> nil) do
  begin
    Prev := Elem^.FPrevElement;
    FreeAndNil(Elem);
    Elem := Prev;
  end;

  inherited Destroy;
end;

end.

