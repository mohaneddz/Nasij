import { createTheme } from '@mui/material'

const shadows = [
  'none',
  '0 1px 2px 0 rgba(0, 0, 0, 0.05)', // 1
  '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)', // 2
  '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)', // 3
  '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1)', // 4
  ...Array(20).fill('none') // MUI requires 25 shadows, filler
]

export const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#475569',
      light: '#94a3b8',
      dark: '#334155',
      contrastText: '#fff',
    },
    secondary: {
      main: '#475569', // slate-600
    },
    success: {
      main: '#6b8f7a',
      light: '#e6eee9',
      dark: '#486556',
    },
    error: {
      main: '#b56b6b',
      light: '#f1e4e4',
      dark: '#884d4d',
    },
    warning: {
      main: '#a48a55',
      light: '#eee8dc',
      dark: '#745f37',
    },
    info: {
      main: '#64748b',
      light: '#e2e8f0',
      dark: '#475569',
    },
    text: {
      primary: '#111827', // gray-900
      secondary: '#4b5563', // gray-600
      disabled: '#9ca3af',
    },
    background: {
      default: '#f3f4f6', // gray-100
      paper: '#ffffff',
    },
    divider: '#e5e7eb', // gray-200
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica Neue", sans-serif',
    h1: { fontWeight: 700, letterSpacing: '-0.025em' },
    h2: { fontWeight: 700, letterSpacing: '-0.025em' },
    h3: { fontWeight: 700, letterSpacing: '-0.02em' },
    h4: { fontWeight: 700, letterSpacing: '-0.02em' },
    h5: { fontWeight: 600, letterSpacing: '-0.01em' },
    h6: { fontWeight: 600, letterSpacing: '-0.01em' },
    subtitle1: { fontWeight: 500, letterSpacing: '-0.01em' },
    body1: { fontSize: '0.95rem' },
    body2: { fontSize: '0.875rem', color: '#4b5563' },
    button: { textTransform: 'none', fontWeight: 600 },
    overline: { fontWeight: 600, letterSpacing: '0.05em', color: '#4b5563', textTransform: 'uppercase' }
  },
  shape: {
    borderRadius: 8,
  },
  shadows,
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb',
          borderRadius: '8px',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          borderRadius: '8px',
        },
        elevation1: {
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb',
        },
        elevation2: {
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb',
        }
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: '6px',
          padding: '6px 16px',
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
          },
        },
        contained: {
          border: '1px solid transparent',
          boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        }
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 500,
          borderRadius: '6px',
        }
      }
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: '6px',
          margin: '2px 8px',
          padding: '8px 12px',
          color: '#4b5563',
          '&:hover': { 
            backgroundColor: '#f3f4f6',
            color: '#111827'
          },
          '&.Mui-selected': {
            backgroundColor: '#f1f5f9',
            color: '#334155',
            '&:hover': { backgroundColor: '#e2e8f0' },
            '& .MuiListItemIcon-root': { color: '#334155' },
            '& .MuiListItemText-primary': { color: '#334155', fontWeight: 600 },
          },
        }
      }
    },
    MuiListItemIcon: {
      styleOverrides: {
        root: {
          color: '#6b7280',
          minWidth: '36px',
        }
      }
    },
    MuiDivider: {
      styleOverrides: {
        root: {
          borderColor: '#e5e7eb'
        }
      }
    }
  }
})
