import Slider from '@react-native-community/slider';
import { useState } from 'react';
import { Keyboard, View } from 'react-native';
import { Text, TextInput, useTheme } from 'react-native-paper';

type Props = {
  label: string;
  value: number;
  min: number;
  max: number;
  step?: number;
  onChange: (value: number) => void;
  format?: (value: number) => string;
  parse?: (text: string) => number;
  mask?: (text: string) => string;
};

const trim = (v: number) =>
  Number.isInteger(v) ? String(v) : String(Number(v.toFixed(1)));

/// A slider paired with a type-in field, both bound to one value. Optional
/// format/parse support non-decimal displays (e.g. pace as m:ss); mask
/// reshapes raw keystrokes (e.g. digits → m:ss) as the user types.
///
/// The field keeps a local buffer while focused so partial input isn't
/// reformatted or clamped mid-type; on blur it snaps back to the canonical
/// value. The slider still tracks live off the parsed value.
export function SliderInput({
  label,
  value,
  min,
  max,
  step = 1,
  onChange,
  format,
  parse,
  mask,
}: Props) {
  const theme = useTheme();
  const clamped = Math.min(Math.max(value, min), max);
  const canonical = format ? format(clamped) : trim(clamped);
  const [editing, setEditing] = useState<string | null>(null);

  return (
    <View style={{ gap: 4 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
        <Text style={{ flex: 1 }}>{label}</Text>
        <TextInput
          mode="outlined"
          dense
          style={{ width: 92 }}
          keyboardType="numeric"
          value={editing ?? canonical}
          onFocus={() => setEditing(canonical)}
          onBlur={() => setEditing(null)}
          onChangeText={(text) => {
            const shown = mask ? mask(text) : text;
            setEditing(shown);
            const n = parse ? parse(shown) : Number(shown.replace(/[^0-9.]/g, ''));
            if (!Number.isNaN(n)) onChange(Math.min(Math.max(n, min), max));
          }}
        />
      </View>
      <Slider
        minimumValue={min}
        maximumValue={max}
        step={step}
        value={clamped}
        onValueChange={(v) => {
          if (editing !== null) {
            setEditing(null);
            Keyboard.dismiss();
          }
          onChange(v);
        }}
        minimumTrackTintColor={theme.colors.primary}
        thumbTintColor={theme.colors.primary}
      />
    </View>
  );
}
