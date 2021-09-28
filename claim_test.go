package iden3

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestOne(t *testing.T) {
	var schemaHash SchemaHash
	claim := NewClaim(schemaHash, WithFlagExpiration(true))
	require.Zero(t, claim.value)
	for i := 1; i < 4; i++ {
		require.Zero(t, claim.index[i])
	}
	for i := 0; i < 32; i++ {
		if i == 16 {
			require.Equal(t, byte(0b1000), claim.index[0][i],
				int253ToString(claim.index[0]))
		} else {
			require.Zero(t, claim.index[0][i], int253ToString(claim.index[0]))
		}
	}
}

func int253ToString(i int253) string {
	var b bytes.Buffer
	for j := len(i) - 1; j >= 0; j-- {
		b.WriteString(fmt.Sprintf("% 08b", i[j]))
	}
	return b.String()
}
