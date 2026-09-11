import { render, screen } from '@testing-library/react';
import App from './App';

test('renders the student-teacher portal heading', () => {
  render(<App />);
  expect(screen.getByText(/student-teacher portal/i)).toBeInTheDocument();
});
